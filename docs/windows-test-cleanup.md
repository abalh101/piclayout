# Windows test resource cleanup

The four previous cleanup failures were reproduced with both default concurrency
and `--concurrency=1`. They were test resource-lifecycle failures; reducing
concurrency alone did not fix them. Windows returned OS error 32 during deletion.

| Failing test file | Temporary files involved | Lifecycle issue |
| --- | --- | --- |
| `test/demo_projects_test.dart` | `demo_edit_test*/piclayout_projects/<id>/project.json` and its `.tmp` save file | `controller.dispose()` launched its final repository save without the test awaiting it before directory deletion. |
| `test/design_library_editor_test.dart` | `piclayout_design_ui_*/image.png` | Native image reads/decoding and cached image references were started during a fake-clock widget test; teardown did not explicitly complete their lifecycle before cleanup. |
| `test/layout_recommendation_ui_test.dart` | `recommend_ui*/photo0.png` through `photo5.png` | Review thumbnails and canvas image loading used real file/native operations while the test advanced fake time; a directory was shared across tests. |
| `test/text_overlay_editor_test.dart` | `piclayout_ui_*/photo.png` | The canvas initiated native image loading, and controller/widget/image cleanup was not safely ordered before temporary-directory cleanup. |

The original recursive-delete exception identified the parent directory, not an
individual child file. The table describes the files and operations belonging to
each failing fixture; it does not claim an OS handle trace for every child.
The shared cleanup helper now deletes files explicitly before the directory so
any future file deletion failure identifies the affected file.

## Fixes

- The demo teardown disposes the controller, queues a repository save after the
  disposal-triggered save, and awaits it. The earlier directory teardown runs
  only afterward, using `addTearDown`'s reverse registration order.
- Image-backed widget tests use `test/support/real_image_io.dart` and
  `WidgetTester.runAsync` for work that needs the real event loop. On exit, the
  helper unmounts the widget tree and clears both normal and live image-cache
  references. Cleanup runs on the real event loop as well.
- Each image-backed UI test owns its own temporary directory. Provider containers
  and controllers are registered for disposal after directory cleanup is
  registered, so they are disposed first. The text controller is also disposed
  when an assertion fails, rather than only at the end of the successful path.
- The design-library fixture provides in-memory onboarding state instead of
  launching a real path-provider request. It explicitly clears its save
  notification snackbar before further taps; advancing fake time does not expire
  a timer started on the real event loop.
- Cleanup checks that the directory is beneath the system temporary directory.
  Every file deletion and final directory deletion is awaited. There are no
  cleanup-error catches, skipped tests, retries or arbitrary sleeps in the fix.

Production image decoding and export already dispose their descriptors, buffers,
codecs, pictures and output images. Repository operations close files after their
awaited writes. No production code change was needed in this cleanup pass.

## Validation and CI

On Windows, `dart format .` completed, `flutter analyze` found no issues, and both
`flutter test` and `flutter test --concurrency=1` passed **all 116 tests**.
The former failing tests provide the regression coverage; no redundant tests
were added. No test failure or cleanup exception was suppressed.

The push/PR Flutter CI now has Ubuntu and Windows jobs. Both run dependency
resolution, format checking, analysis and the full suite; Windows additionally
runs the serial suite. The remote workflow has not been executed in this session,
so its first successful run remains the confirmation for GitHub-hosted runners.

Reference: [Flutter's `WidgetTester.runAsync` API](https://api.flutter.dev/flutter/flutter_test/WidgetTester/runAsync.html).
