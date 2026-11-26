"""Validate release inputs and configure the Runner identity on the CI checkout."""
from html import unescape
from http.client import HTTPException
from ipaddress import ip_address
import os
from pathlib import Path
import re
from urllib.error import URLError
from urllib.parse import urlsplit
from urllib.request import HTTPRedirectHandler, build_opener


def require(condition, message):
    if not condition:
        raise SystemExit(f"::error::{message}")


def public_host(host):
    if not host:
        return False
    host = host.lower().rstrip(".")
    try:
        return ip_address(host).is_global
    except ValueError:
        labels = host.split(".")
        return (len(labels) >= 2
                and all(re.fullmatch(r"[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?", label)
                        for label in labels)
                and any(character.isalpha() for character in labels[-1])
                and labels[-1] not in {"example", "internal", "invalid", "local", "localdomain", "localhost", "test"}
                and not any(host == domain or host.endswith("." + domain)
                            for domain in ("example.com", "example.net", "example.org"))
                and not any(label in {"your-domain", "yourdomain", "placeholder", "replace-me"}
                            for label in labels))


def public_policy_url(value):
    try:
        url = urlsplit(value)
        return (url.scheme == "https" and url.username is None and public_host(url.hostname)
                and (url.port is None or url.port > 0)
                and not any(character.isspace() or ord(character) < 32 for character in value))
    except ValueError:
        return False


class PublicPolicyRedirect(HTTPRedirectHandler):
    def redirect_request(self, req, fp, code, msg, headers, newurl):
        if not public_policy_url(newurl):
            raise URLError("Privacy policy redirect must point to a public HTTPS address.")
        return super().redirect_request(req, fp, code, msg, headers, newurl)


def check_policy(name, value):
    require(public_policy_url(value), f"Set {name} to the HTTPS URL of your published privacy policy.")
    try:
        with build_opener(PublicPolicyRedirect()).open(value, timeout=15) as response:
            require(response.status == 200
                    and response.headers.get_content_type() in {"text/html", "application/xhtml+xml"},
                    f"{name} must open a public HTML privacy policy.")
            body = response.read(2_000_001)
            charset = response.headers.get_content_charset() or "utf-8"
    except (OSError, ValueError, HTTPException):
        raise SystemExit(f"::error::{name} could not be reached over public HTTPS. Check the published URL.") from None

    require(len(body) <= 2_000_000, f"{name} could not be checked because the HTML response exceeds 2 MB.")
    try:
        page = unescape(body.decode(charset, errors="replace")).casefold()
    except LookupError:
        raise SystemExit(f"::error::{name} uses an unrecognized page encoding.") from None
    require("piclayout" in page, f"{name} must name PicLayout in the published policy.")
    require("publisher legal name and contact address" not in page
            and "public support and privacy email" not in page,
            f"{name} still contains the publisher or support placeholder. Publish the completed policy.")


def main():
    require(re.fullmatch(r"(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)",
                         os.environ["MARKETING_VERSION"]), "Use a marketing version such as 1.0.0.")
    require(re.fullmatch(r"[1-9][0-9]{0,3}", os.environ["BUILD_NUMBER"]),
            "Use a positive build number from 1 to 9999.")
    email = os.environ.get("SUPPORT_EMAIL", "")
    require(re.fullmatch(r"[A-Za-z0-9.!#$%&'*+/=?^_`{|}~-]+@[^\s@]+", email)
            and public_host(email.rsplit("@", 1)[1]),
            "Set the SUPPORT_EMAIL repository variable to your public support address.")

    identity = Path("ios/Flutter/AppIdentity.xcconfig")
    default = re.search(r"^PICLAYOUT_BUNDLE_ID = (.+)$", identity.read_text(), re.M)[1]
    bundle = os.environ.get("IOS_BUNDLE_ID") or default
    require(re.fullmatch(r"[A-Za-z0-9-]+(?:\.[A-Za-z0-9-]+)+", bundle),
            "IOS_BUNDLE_ID must be an explicit reverse-DNS bundle identifier.")

    for name in ("PRIVACY_POLICY_URL", "PRIVACY_POLICY_URL_DE"):
        check_policy(name, os.environ.get(name, ""))

    identity.with_name("LocalIdentity.xcconfig").write_text(f"PICLAYOUT_BUNDLE_ID = {bundle}\n")
    with open(os.environ["GITHUB_ENV"], "a") as output:
        output.write(f"PICLAYOUT_BUNDLE_ID={bundle}\n")


if __name__ == "__main__":
    main()
