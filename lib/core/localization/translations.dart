// Order: German, English, Arabic, Turkish, French, Spanish.
const translations = <String, List<String>>{
  "recRecommended": [
    "Empfohlen",
    "Recommended",
    "مقترح",
    "Önerilen",
    "Recommandé",
    "Recomendado"
  ],
  "recAuto": [
    "Auto Layout",
    "Auto layout",
    "تخطيط تلقائي",
    "Otomatik düzen",
    "Disposition auto",
    "Diseño automático"
  ],
  "recLoading": [
    "Fotoformate werden gelesen …",
    "Reading photo dimensions…",
    "جارٍ قراءة أبعاد الصور…",
    "Fotoğraf boyutları okunuyor…",
    "Lecture des dimensions des photos…",
    "Leyendo las dimensiones de las fotos…"
  ],
  "recFormat": [
    "Passend zu Fotoanzahl und Zielformat",
    "Fits the photo count and target format",
    "يناسب عدد الصور وتنسيق الإخراج",
    "Fotoğraf sayısına ve hedef biçime uygun",
    "Adapté au nombre de photos et au format cible",
    "Se adapta al número de fotos y al formato de destino"
  ],
  "recPortrait": [
    "Passt zu vielen Hochformatbildern",
    "Fits many portrait photos",
    "يناسب الصور الرأسية المتعددة",
    "Dikey fotoğraflara uygun",
    "Adapté aux photos en portrait",
    "Ideal para fotos verticales"
  ],
  "recLandscape": [
    "Breite Felder für Querformatbilder",
    "Wide cells for landscape photos",
    "خانات عريضة للصور الأفقية",
    "Yatay fotoğraflar için geniş alanlar",
    "Cases larges pour les photos en paysage",
    "Espacios anchos para fotos horizontales"
  ],
  "recSquare": [
    "Ausgeglichenes Raster für ein Quadrat",
    "Balanced grid for a square",
    "شبكة متوازنة لتنسيق مربع",
    "Kare için dengeli ızgara",
    "Grille équilibrée pour un carré",
    "Cuadrícula equilibrada para un cuadrado"
  ],
  "recMixed": [
    "Abwechslungsreich für gemischte Fotoformate",
    "Varied layout for mixed photo formats",
    "تخطيط متنوع لأبعاد صور مختلفة",
    "Farklı fotoğraf biçimleri için çeşitli düzen",
    "Disposition variée pour des formats mixtes",
    "Diseño variado para formatos de foto mixtos"
  ],
  "recStorySix": [
    "Gut für 6 Bilder im Story-Format",
    "Great for 6 photos in story format",
    "مناسب لست صور بتنسيق القصة",
    "Hikâye biçiminde 6 fotoğraf için uygun",
    "Idéal pour 6 photos au format story",
    "Ideal para 6 fotos en formato historia"
  ],
  "recWideHero": [
    "Hebt das erste breite Foto hervor",
    "Highlights the first wide photo",
    "يبرز الصورة العريضة الأولى",
    "İlk geniş fotoğrafı öne çıkarır",
    "Met en valeur la première photo large",
    "Destaca la primera foto ancha"
  ],
  "recTallHero": [
    "Hebt das erste hohe Foto hervor",
    "Highlights the first tall photo",
    "يبرز الصورة الطويلة الأولى",
    "İlk uzun fotoğrafı öne çıkarır",
    "Met en valeur la première photo haute",
    "Destaca la primera foto alta"
  ],
  "introTitle0": [
    "Willkommen bei PicLayout",
    "Welcome to PicLayout",
    "مرحبًا بك في PicLayout",
    "PicLayout’a hoş geldiniz",
    "Bienvenue dans PicLayout",
    "Te damos la bienvenida a PicLayout"
  ],
  "introBody0": [
    "Erstelle Collagen für Stories, Posts und Erinnerungen. Probiere am Ende ein Beispiel aus oder starte mit deinen Fotos.",
    "Create collages for stories, posts and memories. Try an example at the end or start with your own photos.",
    "أنشئ تصاميم للقصص والمنشورات والذكريات. جرّب مثالًا في النهاية أو ابدأ بصورك.",
    "Hikâyeler, gönderiler ve anılar için kolajlar oluşturun. Son adımda bir örnek deneyin veya kendi fotoğraflarınızla başlayın.",
    "Créez des collages pour vos stories, publications et souvenirs. Essayez un exemple à la fin ou commencez avec vos photos.",
    "Crea collages para historias, publicaciones y recuerdos. Al final, prueba un ejemplo o empieza con tus fotos."
  ],
  "introTitle1": [
    "Fotos auswählen",
    "Choose photos",
    "اختيار الصور",
    "Fotoğraf seçin",
    "Choisir des photos",
    "Elegir fotos"
  ],
  "introBody1": [
    "Wähle 1 bis 12 Fotos und ordne sie nach Wunsch an. Deine Originalfotos werden nicht überschrieben.",
    "Choose 1 to 12 photos and arrange them as you like. Your original photos are never overwritten.",
    "اختر من صورة واحدة إلى 12 صورة ورتّبها كما تشاء. لن تُستبدل صورك الأصلية.",
    "1 ile 12 fotoğraf seçip istediğiniz sıraya koyun. Orijinal fotoğraflarınızın üzerine yazılmaz.",
    "Choisissez de 1 à 12 photos et classez-les à votre goût. Vos photos originales ne sont jamais écrasées.",
    "Elige entre 1 y 12 fotos y ordénalas a tu gusto. Tus fotos originales no se sobrescriben."
  ],
  "introTitle2": [
    "Layouts und Vorlagen",
    "Layouts and templates",
    "التخطيطات والقوالب",
    "Düzenler ve şablonlar",
    "Dispositions et modèles",
    "Diseños y plantillas"
  ],
  "introBody2": [
    "Wähle ein Layout, merke dir Favoriten und speichere eigene Vorlagen. Mit Layoutvariation entdeckst du neue Aufteilungen.",
    "Choose a layout, mark favorites and save your own templates. Layout variation helps you discover new arrangements.",
    "اختر تخطيطًا واحفظ المفضلة وقوالبك الخاصة. جرّب تنويع التخطيط لاكتشاف ترتيبات جديدة.",
    "Bir düzen seçin, favorileri işaretleyin ve kendi şablonlarınızı kaydedin. Düzen çeşitlendirme ile yeni yerleşimler keşfedin.",
    "Choisissez une disposition, ajoutez des favoris et enregistrez vos modèles. Variez la disposition pour découvrir de nouveaux agencements.",
    "Elige un diseño, marca favoritos y guarda tus plantillas. Prueba la variación de diseño para descubrir nuevas distribuciones."
  ],
  "introTitle3": [
    "Deine Collage bearbeiten",
    "Edit your collage",
    "تعديل تصميمك",
    "Kolajınızı düzenleyin",
    "Modifier votre collage",
    "Editar tu collage"
  ],
  "introBody3": [
    "Schneide Fotos zu, zoome und drehe sie. Ergänze Text, Sticker, Filter und Hintergründe im Style Studio.",
    "Crop, zoom and rotate photos. Add text, stickers, filters and backgrounds in Style Studio.",
    "اقتصّ الصور وكبّرها ودوّرها. أضف النصوص والملصقات والفلاتر والخلفيات في استوديو الأنماط.",
    "Fotoğrafları kırpın, yakınlaştırın ve döndürün. Metin, çıkartma, filtre ve Stil Stüdyosu arka planları ekleyin.",
    "Recadrez, zoomez et faites pivoter vos photos. Ajoutez du texte, des stickers, des filtres et des fonds dans le Studio de style.",
    "Recorta, amplía y gira fotos. Añade texto, stickers, filtros y fondos en el Estudio de estilo."
  ],
  "introTitle4": [
    "Speichern und teilen",
    "Save and share",
    "الحفظ والمشاركة",
    "Kaydedin ve paylaşın",
    "Enregistrer et partager",
    "Guardar y compartir"
  ],
  "introBody4": [
    "Speichere deine Collage in der Galerie oder teile sie mit Instagram, Snapchat, TikTok und WhatsApp. Sichere eine bearbeitbare .piclayout-Projektdatei und importiere sie später wieder.",
    "Save your collage to the gallery or share it with Instagram, Snapchat, TikTok and WhatsApp. Back up an editable .piclayout project file and import it again later.",
    "احفظ تصميمك في المعرض أو شاركه عبر Instagram وSnapchat وTikTok وWhatsApp. احفظ ملف مشروع ‎.piclayout قابلًا للتعديل واستورده لاحقًا.",
    "Kolajınızı galeriye kaydedin veya Instagram, Snapchat, TikTok ve WhatsApp ile paylaşın. Düzenlenebilir .piclayout proje dosyasını yedekleyip daha sonra içe aktarın.",
    "Enregistrez votre collage dans la galerie ou partagez-le avec Instagram, Snapchat, TikTok et WhatsApp. Sauvegardez un projet .piclayout modifiable pour le réimporter plus tard.",
    "Guarda tu collage en la galería o compártelo con Instagram, Snapchat, TikTok y WhatsApp. Guarda un proyecto .piclayout editable e impórtalo más adelante."
  ],
  "introStart": [
    "Loslegen",
    "Get started",
    "ابدأ الآن",
    "Başlayın",
    "Commencer",
    "Empezar"
  ],
  "introNext": ["Weiter", "Next", "التالي", "İleri", "Suivant", "Siguiente"],
  "introBack": ["Zurück", "Back", "السابق", "Geri", "Précédent", "Atrás"],
  "introSkip": ["Überspringen", "Skip", "تخطي", "Atla", "Passer", "Omitir"],
  "introReplay": [
    "Onboarding erneut anzeigen",
    "Show onboarding again",
    "عرض المقدمة مجددًا",
    "Tanıtımı yeniden göster",
    "Revoir la présentation",
    "Ver la introducción de nuevo"
  ],
  "introLocal": [
    "Die Bearbeitung passiert lokal auf deinem Gerät. Deine Originalfotos bleiben unverändert.",
    "Editing happens locally on your device. Your original photos stay unchanged.",
    "يجري التعديل محليًا على جهازك. تبقى صورك الأصلية دون تغيير.",
    "Düzenleme cihazınızda yerel olarak yapılır. Orijinal fotoğraflarınız değişmez.",
    "Les modifications se font localement sur votre appareil. Vos photos originales restent intactes.",
    "La edición se realiza localmente en tu dispositivo. Tus fotos originales permanecen intactas."
  ],
  "demoOpen": [
    "Beispiel öffnen",
    "Open an example",
    "فتح مثال",
    "Örnek aç",
    "Ouvrir un exemple",
    "Abrir un ejemplo"
  ],
  "demoProjects": [
    "Beispielprojekte",
    "Example projects",
    "مشاريع تجريبية",
    "Örnek projeler",
    "Projets exemples",
    "Proyectos de ejemplo"
  ],
  "demoDescription": [
    "Wähle ein Design zum Ausprobieren. Du erhältst jedes Mal eine eigene bearbeitbare Kopie mit abstrakten Demo-Bildern.",
    "Choose a design to try. Each opening creates your own editable copy with abstract demo images.",
    "اختر تصميمًا لتجربته. ينشئ كل فتح نسخة خاصة بك قابلة للتعديل بصور تجريبية مجردة.",
    "Denemek için bir tasarım seçin. Her açışınızda soyut örnek görsellerle düzenlenebilir yeni bir kopya oluşturulur.",
    "Choisissez un design à essayer. Chaque ouverture crée votre propre copie modifiable avec des images abstraites.",
    "Elige un diseño para probar. Cada vez que lo abres se crea una copia editable con imágenes abstractas de muestra."
  ],
  "demoStory": [
    "Instagram Story Collage",
    "Instagram story collage",
    "تصميم قصة Instagram",
    "Instagram hikâye kolajı",
    "Collage story Instagram",
    "Collage para historia de Instagram"
  ],
  "demoTravel": [
    "Reise Collage",
    "Travel collage",
    "تصميم الرحلات",
    "Seyahat kolajı",
    "Collage de voyage",
    "Collage de viaje"
  ],
  "demoBirthday": [
    "Geburtstag / Event Collage",
    "Birthday / event collage",
    "تصميم عيد ميلاد أو مناسبة",
    "Doğum günü / etkinlik kolajı",
    "Collage anniversaire / événement",
    "Collage de cumpleaños / evento"
  ],
  "demoMinimal": [
    "Minimal Clean Collage",
    "Minimal clean collage",
    "تصميم بسيط وأنيق",
    "Sade ve temiz kolaj",
    "Collage minimaliste",
    "Collage minimalista"
  ],
  "demoPost": [
    "Social Media Post",
    "Social media post",
    "منشور للشبكات الاجتماعية",
    "Sosyal medya gönderisi",
    "Publication sur les réseaux sociaux",
    "Publicación para redes sociales"
  ],
  "tipsReset": [
    "Tipps zurücksetzen",
    "Reset tips",
    "إعادة ضبط النصائح",
    "İpuçlarını sıfırla",
    "Réinitialiser les conseils",
    "Restablecer consejos"
  ],
  "tipsResetDone": [
    "Tipps werden beim nächsten Öffnen wieder angezeigt.",
    "Tips will appear again the next time you open a screen.",
    "ستظهر النصائح مجددًا عند فتح الشاشة في المرة القادمة.",
    "İpuçları bir ekranı bir sonraki açışınızda yeniden gösterilecek.",
    "Les conseils réapparaîtront à la prochaine ouverture d’un écran.",
    "Los consejos volverán a mostrarse la próxima vez que abras una pantalla."
  ],
  "tipPhoto": [
    "Tippe ein Foto an, um es zu bearbeiten.",
    "Tap a photo to edit it.",
    "اضغط على صورة لتعديلها.",
    "Düzenlemek için bir fotoğrafa dokunun.",
    "Touchez une photo pour la modifier.",
    "Toca una foto para editarla."
  ],
  "tipZoom": [
    "Mit zwei Fingern auf dem Foto in der Collage zoomen.",
    "Use two fingers on a photo in the collage to zoom.",
    "استخدم إصبعين على الصورة في التصميم للتكبير والتصغير.",
    "Yakınlaştırmak için kolajdaki fotoğraf üzerinde iki parmağınızı kullanın.",
    "Utilisez deux doigts sur une photo du collage pour zoomer.",
    "Usa dos dedos sobre una foto del collage para ampliar."
  ],
  "tipDrag": [
    "Ziehe Text oder Sticker in der Collage, um sie zu verschieben.",
    "Drag text or stickers in the collage to move them.",
    "اسحب النص أو الملصق داخل التصميم لتحريكه.",
    "Taşımak için kolajdaki metni veya çıkartmayı sürükleyin.",
    "Faites glisser le texte ou les stickers dans le collage pour les déplacer.",
    "Arrastra el texto o los stickers en el collage para moverlos."
  ],
  "tipExport": [
    "Wähle Galerie oder Social Media. Veröffentlicht wird in der Ziel-App.",
    "Choose Gallery or Social Media. Publishing happens in the destination app.",
    "اختر المعرض أو وسائل التواصل. يتم النشر في التطبيق المستهدف.",
    "Galeri veya sosyal medyayı seçin. Yayınlama hedef uygulamada yapılır.",
    "Choisissez Galerie ou Réseaux sociaux. La publication se fait dans l’application choisie.",
    "Elige Galería o Redes sociales. La publicación se realiza en la aplicación de destino."
  ],
  "newCollage": [
    "Neue Collage",
    "New collage",
    "تصميم جديد",
    "Yeni kolaj",
    "Nouveau collage",
    "Nuevo collage"
  ],
  "recentProjects": [
    "Zuletzt bearbeitet",
    "Recent projects",
    "المشاريع الأخيرة",
    "Son projeler",
    "Projets récents",
    "Proyectos recientes"
  ],
  "emptyProjectsTitle": [
    "Noch keine Collagen",
    "No collages yet",
    "لا توجد تصاميم بعد",
    "Henüz kolaj yok",
    "Aucun collage",
    "Aún no hay collages"
  ],
  "emptyProjectsBody": [
    "Wähle Fotos aus und erstelle deine erste Collage.",
    "Pick photos and create your first collage.",
    "اختر صوراً لإنشاء تصميمك الأول.",
    "İlk kolajınızı oluşturmak için fotoğraf seçin.",
    "Choisissez des photos pour votre premier collage.",
    "Elige fotos para crear tu primer collage."
  ],
  "settings": [
    "Einstellungen",
    "Settings",
    "الإعدادات",
    "Ayarlar",
    "Paramètres",
    "Ajustes"
  ],
  "localPrivacyNote": [
    "Die Bearbeitung läuft lokal auf deinem Gerät. Es gibt keine Anmeldung, keine Analyse-SDKs und keine Bild-Uploads.",
    "Editing happens locally on your device. There are no accounts, analytics SDKs, or image uploads.",
    "تتم المعالجة محلياً على جهازك. لا حسابات أو أدوات تحليل أو رفع صور.",
    "Düzenleme cihazınızda yapılır. Hesap, analiz SDK’sı veya fotoğraf yükleme yoktur.",
    "Les retouches se font sur votre appareil. Sans compte, outil d’analyse ni envoi d’images.",
    "La edición se realiza en tu dispositivo. Sin cuentas, análisis ni subida de imágenes."
  ],
  "selectedPhotos": [
    "Ausgewählte Fotos",
    "Selected photos",
    "الصور المختارة",
    "Seçilen fotoğraflar",
    "Photos sélectionnées",
    "Fotos seleccionadas"
  ],
  "createCollage": [
    "Collage erstellen",
    "Create collage",
    "إنشاء تصميم",
    "Kolaj oluştur",
    "Créer un collage",
    "Crear collage"
  ],
  "remove": ["Entfernen", "Remove", "إزالة", "Kaldır", "Retirer", "Quitar"],
  "cancel": ["Abbrechen", "Cancel", "إلغاء", "İptal", "Annuler", "Cancelar"],
  "rename": [
    "Umbenennen",
    "Rename",
    "إعادة تسمية",
    "Yeniden adlandır",
    "Renommer",
    "Renombrar"
  ],
  "duplicate": [
    "Duplizieren",
    "Duplicate",
    "نسخ",
    "Çoğalt",
    "Dupliquer",
    "Duplicar"
  ],
  "delete": ["Löschen", "Delete", "حذف", "Sil", "Supprimer", "Eliminar"],
  "export": [
    "Exportieren",
    "Export",
    "تصدير",
    "Dışa aktar",
    "Exporter",
    "Exportar"
  ],
  "share": ["Teilen", "Share", "مشاركة", "Paylaş", "Partager", "Compartir"],
  "layout": [
    "Layout",
    "Layout",
    "التخطيط",
    "Düzen",
    "Disposition",
    "Distribución"
  ],
  "favorites": [
    "Favoriten",
    "Favorites",
    "المفضلة",
    "Favoriler",
    "Favoris",
    "Favoritos"
  ],
  "addFavorite": [
    "Zu Favoriten hinzufügen",
    "Add to favorites",
    "إضافة للمفضلة",
    "Favorilere ekle",
    "Ajouter aux favoris",
    "Añadir a favoritos"
  ],
  "removeFavorite": [
    "Aus Favoriten entfernen",
    "Remove from favorites",
    "إزالة من المفضلة",
    "Favorilerden kaldır",
    "Retirer des favoris",
    "Quitar de favoritos"
  ],
  "otherLayouts": [
    "Weitere Layouts",
    "Other layouts",
    "تخطيطات أخرى",
    "Diğer düzenler",
    "Autres dispositions",
    "Otras distribuciones"
  ],
  "variation": [
    "Variation",
    "Variation",
    "تنويع",
    "Varyasyon",
    "Variation",
    "Variación"
  ],
  "saveAsTemplate": [
    "Als Vorlage speichern",
    "Save as template",
    "حفظ كقالب",
    "Şablon olarak kaydet",
    "Enregistrer comme modèle",
    "Guardar como plantilla"
  ],
  "saveTemplate": [
    "Vorlage speichern",
    "Save template",
    "حفظ القالب",
    "Şablonu kaydet",
    "Enregistrer le modèle",
    "Guardar plantilla"
  ],
  "myTemplates": [
    "Meine Vorlagen",
    "My templates",
    "قوالبي",
    "Şablonlarım",
    "Mes modèles",
    "Mis plantillas"
  ],
  "templateName": [
    "Vorlagenname",
    "Template name",
    "اسم القالب",
    "Şablon adı",
    "Nom du modèle",
    "Nombre de plantilla"
  ],
  "includeTemplateText": [
    "Text-Overlays in die Vorlage übernehmen",
    "Include text overlays in template",
    "تضمين النصوص في القالب",
    "Şablona metinleri ekle",
    "Inclure les textes dans le modèle",
    "Incluir textos en la plantilla"
  ],
  "noTemplates": [
    "Noch keine eigenen Vorlagen gespeichert.",
    "No custom templates saved yet.",
    "لم يتم حفظ قوالب بعد.",
    "Henüz şablon kaydedilmedi.",
    "Aucun modèle enregistré.",
    "Aún no hay plantillas guardadas."
  ],
  "applyTemplate": [
    "Anwenden",
    "Apply",
    "تطبيق",
    "Uygula",
    "Appliquer",
    "Aplicar"
  ],
  "templateSaved": [
    "Vorlage gespeichert",
    "Template saved",
    "تم حفظ القالب",
    "Şablon kaydedildi",
    "Modèle enregistré",
    "Plantilla guardada"
  ],
  "layoutAdjusted": [
    "Für diese Bildanzahl wurde ein passendes Layout gewählt.",
    "A compatible layout was chosen for this photo count.",
    "تم اختيار تخطيط مناسب لعدد الصور.",
    "Fotoğraf sayısına uygun düzen seçildi.",
    "Une disposition adaptée au nombre de photos a été choisie.",
    "Se eligió una distribución para esta cantidad de fotos."
  ],
  "format": ["Format", "Format", "التنسيق", "Biçim", "Format", "Formato"],
  "style": ["Stil", "Style", "النمط", "Stil", "Style", "Estilo"],
  "photo": ["Foto", "Photo", "صورة", "Fotoğraf", "Photo", "Foto"],
  "textOverlay": ["Text", "Text", "نص", "Metin", "Texte", "Texto"],
  "addText": [
    "Text hinzufügen",
    "Add text",
    "إضافة نص",
    "Metin ekle",
    "Ajouter du texte",
    "Añadir texto"
  ],
  "textContent": [
    "Textinhalt",
    "Text content",
    "محتوى النص",
    "Metin içeriği",
    "Contenu du texte",
    "Contenido del texto"
  ],
  "fontSize": [
    "Schriftgröße",
    "Font size",
    "حجم الخط",
    "Yazı boyutu",
    "Taille du texte",
    "Tamaño del texto"
  ],
  "textColor": [
    "Textfarbe",
    "Text color",
    "لون النص",
    "Metin rengi",
    "Couleur du texte",
    "Color del texto"
  ],
  "textBackground": [
    "Texthintergrund",
    "Text background",
    "خلفية النص",
    "Metin arka planı",
    "Fond du texte",
    "Fondo del texto"
  ],
  "textAlignment": [
    "Ausrichtung",
    "Alignment",
    "المحاذاة",
    "Hizalama",
    "Alignement",
    "Alineación"
  ],
  "none": ["Keiner", "None", "لا شيء", "Yok", "Aucun", "Ninguno"],
  "left": ["Links", "Left", "يسار", "Sol", "Gauche", "Izquierda"],
  "center": ["Mitte", "Center", "وسط", "Orta", "Centre", "Centro"],
  "right": ["Rechts", "Right", "يمين", "Sağ", "Droite", "Derecha"],
  "white": ["Weiß", "White", "أبيض", "Beyaz", "Blanc", "Blanco"],
  "black": ["Schwarz", "Black", "أسود", "Siyah", "Noir", "Negro"],
  "blue": ["Blau", "Blue", "أزرق", "Mavi", "Bleu", "Azul"],
  "red": ["Rot", "Red", "أحمر", "Kırmızı", "Rouge", "Rojo"],
  "yellow": ["Gelb", "Yellow", "أصفر", "Sarı", "Jaune", "Amarillo"],
  "selectTextHint": [
    "Tippe auf einen Text in der Collage oder füge einen neuen hinzu.",
    "Tap text on the collage or add a new one.",
    "اضغط نصاً في التصميم أو أضف نصاً جديداً.",
    "Kolajdaki metne dokunun veya yenisini ekleyin.",
    "Touchez un texte du collage ou ajoutez-en un.",
    "Toca un texto del collage o añade uno nuevo."
  ],
  "spacing": [
    "Abstand",
    "Spacing",
    "التباعد",
    "Aralık",
    "Espacement",
    "Espaciado"
  ],
  "outerMargin": [
    "Außenrand",
    "Outer margin",
    "الهامش الخارجي",
    "Dış kenar",
    "Marge extérieure",
    "Margen exterior"
  ],
  "cornerRadius": [
    "Eckenradius",
    "Corner radius",
    "استدارة الزوايا",
    "Köşe yarıçapı",
    "Arrondi des coins",
    "Radio de esquinas"
  ],
  "stagger": [
    "Versatz",
    "Stagger",
    "الإزاحة",
    "Kaydırma",
    "Décalage",
    "Desplazamiento"
  ],
  "background": [
    "Hintergrund",
    "Background",
    "الخلفية",
    "Arka plan",
    "Arrière-plan",
    "Fondo"
  ],
  "fill": ["Ausfüllen", "Fill", "ملء", "Doldur", "Remplir", "Rellenar"],
  "fit": ["Einpassen", "Fit", "احتواء", "Sığdır", "Ajuster", "Ajustar"],
  "resetCrop": [
    "Ausschnitt zurücksetzen",
    "Reset crop",
    "إعادة ضبط القص",
    "Kırpmayı sıfırla",
    "Réinitialiser le cadrage",
    "Restablecer recorte"
  ],
  "rotate": ["Drehen", "Rotate", "تدوير", "Döndür", "Tourner", "Girar"],
  "flip": ["Spiegeln", "Flip", "عكس", "Yansıt", "Retourner", "Voltear"],
  "replace": [
    "Ersetzen",
    "Replace",
    "استبدال",
    "Değiştir",
    "Remplacer",
    "Reemplazar"
  ],
  "saveProject": [
    "Projekt speichern",
    "Save project",
    "حفظ المشروع",
    "Projeyi kaydet",
    "Enregistrer le projet",
    "Guardar proyecto"
  ],
  "exportPng": [
    "PNG exportieren",
    "Export PNG",
    "تصدير PNG",
    "PNG dışa aktar",
    "Exporter en PNG",
    "Exportar PNG"
  ],
  "exportJpeg": [
    "JPEG exportieren",
    "Export JPEG",
    "تصدير JPEG",
    "JPEG dışa aktar",
    "Exporter en JPEG",
    "Exportar JPEG"
  ],
  "noPhotoSelected": [
    "Kein Foto ausgewählt",
    "No photo selected",
    "لم يتم اختيار صورة",
    "Fotoğraf seçilmedi",
    "Aucune photo sélectionnée",
    "Ninguna foto seleccionada"
  ],
  "exportSize": [
    "Exportgröße",
    "Export size",
    "حجم التصدير",
    "Dışa aktarma boyutu",
    "Taille d’export",
    "Tamaño de exportación"
  ],
  "projectName": [
    "Projektname",
    "Project name",
    "اسم المشروع",
    "Proje adı",
    "Nom du projet",
    "Nombre del proyecto"
  ],
  "done": ["Fertig", "Done", "تم", "Bitti", "Terminé", "Listo"],
  "permissionOrPickerCancelled": [
    "Auswahl abgebrochen oder keine Fotos gewählt.",
    "Selection cancelled or no photos selected.",
    "تم إلغاء الاختيار أو لم يتم اختيار صور.",
    "Seçim iptal edildi veya fotoğraf seçilmedi.",
    "Sélection annulée ou aucune photo choisie.",
    "Selección cancelada o sin fotos."
  ],
  "unsupportedExportWarning": [
    "Hinweis: Eine höhere Auflösung erzeugt keine zusätzlichen Details, wenn die Quelldateien klein sind.",
    "Note: A higher resolution cannot add detail if the source files are small.",
    "الدقة العالية لا تضيف تفاصيل إذا كانت الصور الأصلية صغيرة.",
    "Kaynak küçükse yüksek çözünürlük ayrıntı eklemez.",
    "Une résolution plus élevée n’ajoute pas de détails aux petites images sources.",
    "Una resolución mayor no añade detalles si los originales son pequeños."
  ],
  "language": ["Sprache", "Language", "اللغة", "Dil", "Langue", "Idioma"],
  "systemLanguage": [
    "Systemsprache verwenden",
    "Use system language",
    "استخدام لغة النظام",
    "Sistem dilini kullan",
    "Utiliser la langue du système",
    "Usar idioma del sistema"
  ],
  "reportProblem": [
    "Problem melden",
    "Report a problem",
    "الإبلاغ عن مشكلة",
    "Sorun bildir",
    "Signaler un problème",
    "Informar de un problema"
  ],
  "reportPrompt": [
    "Bitte beschreibe hier dein Problem",
    "Please describe your problem here",
    "يرجى وصف مشكلتك هنا",
    "Lütfen sorununuzu burada açıklayın",
    "Décrivez votre problème ici",
    "Describe tu problema aquí"
  ],
  "noMail": [
    "Keine E-Mail-App verfügbar. Du kannst die Support-Adresse kopieren.",
    "No email app available. You can copy the support address.",
    "لا يوجد تطبيق بريد. يمكنك نسخ عنوان الدعم.",
    "E-posta uygulaması yok. Destek adresini kopyalayabilirsiniz.",
    "Aucune application e-mail disponible. Copiez l’adresse du support.",
    "No hay aplicación de correo. Puedes copiar la dirección de soporte."
  ],
  "copy": ["Kopieren", "Copy", "نسخ", "Kopyala", "Copier", "Copiar"],
  "copied": ["Kopiert", "Copied", "تم النسخ", "Kopyalandı", "Copié", "Copiado"],
  "privacy": [
    "Datenschutz-Hinweis",
    "Privacy notice",
    "إشعار الخصوصية",
    "Gizlilik bildirimi",
    "Confidentialité",
    "Aviso de privacidad"
  ],
  "version": [
    "App-Version",
    "App version",
    "إصدار التطبيق",
    "Uygulama sürümü",
    "Version de l’application",
    "Versión de la aplicación"
  ],
  "defaults": [
    "Export-Standardeinstellungen",
    "Export defaults",
    "إعدادات التصدير الافتراضية",
    "Varsayılan dışa aktarma ayarları",
    "Paramètres d’export par défaut",
    "Ajustes de exportación predeterminados"
  ],
  "defaultRatio": [
    "Standardformat für neue Collagen",
    "Default ratio for new collages",
    "النسبة الافتراضية للتصاميم الجديدة",
    "Yeni kolajlar için varsayılan oran",
    "Format des nouveaux collages",
    "Formato de nuevos collages"
  ],
  "jpegQuality": [
    "JPEG-Qualität",
    "JPEG quality",
    "جودة JPEG",
    "JPEG kalitesi",
    "Qualité JPEG",
    "Calidad JPEG"
  ],
  "defaultAction": [
    "Standardaktion nach Export",
    "Default export action",
    "إجراء التصدير الافتراضي",
    "Varsayılan dışa aktarma eylemi",
    "Action d’export par défaut",
    "Acción de exportación predeterminada"
  ],
  "gallery": [
    "Galerie speichern",
    "Save to gallery",
    "حفظ في المعرض",
    "Galeriye kaydet",
    "Enregistrer dans la galerie",
    "Guardar en galería"
  ],
  "clearCache": [
    "Temporäre Exportdateien bereinigen",
    "Clear temporary exports",
    "حذف ملفات التصدير المؤقتة",
    "Geçici dışa aktarımları temizle",
    "Effacer les exports temporaires",
    "Borrar exportaciones temporales"
  ],
  "cacheCleared": [
    "Temporäre Exportdateien gelöscht",
    "Temporary exports deleted",
    "تم حذف ملفات التصدير المؤقتة",
    "Geçici dışa aktarımlar silindi",
    "Exports temporaires supprimés",
    "Exportaciones temporales borradas"
  ],
  "about": [
    "Über PicLayout",
    "About PicLayout",
    "حول PicLayout",
    "PicLayout hakkında",
    "À propos de PicLayout",
    "Acerca de PicLayout"
  ],
  "aboutBody": [
    "Collagen gestalten und lokal exportieren. Ohne Cloud, Konto oder Werbung.",
    "Create collages and export locally. No cloud, accounts or ads.",
    "أنشئ تصاميم وصدّرها محلياً. بدون سحابة أو حساب أو إعلانات.",
    "Kolaj oluşturun ve yerel olarak dışa aktarın. Bulut, hesap veya reklam yok.",
    "Créez des collages et exportez localement. Sans cloud, compte ni publicité.",
    "Crea collages y exporta localmente. Sin nube, cuentas ni publicidad."
  ],
  "settingsError": [
    "Einstellungen konnten nicht geladen oder gespeichert werden.",
    "Could not load or save settings.",
    "تعذر تحميل الإعدادات أو حفظها.",
    "Ayarlar yüklenemedi veya kaydedilemedi.",
    "Impossible de charger ou enregistrer les paramètres.",
    "No se pudieron cargar o guardar los ajustes."
  ],
  "retry": [
    "Erneut versuchen",
    "Retry",
    "إعادة المحاولة",
    "Tekrar dene",
    "Réessayer",
    "Reintentar"
  ],
  "operationFailed": [
    "Aktion fehlgeschlagen. Bitte erneut versuchen.",
    "Action failed. Please try again.",
    "فشل الإجراء. حاول مرة أخرى.",
    "İşlem başarısız. Tekrar deneyin.",
    "Échec de l’action. Réessayez.",
    "La acción falló. Inténtalo de nuevo."
  ],
  "editPhoto": [
    "Bearbeiten",
    "Edit photo",
    "تعديل الصورة",
    "Fotoğrafı düzenle",
    "Modifier la photo",
    "Editar foto"
  ],
  "filterIntensity": [
    "Filter-Intensität",
    "Filter intensity",
    "شدة المرشح",
    "Filtre yoğunluğu",
    "Intensité du filtre",
    "Intensidad del filtro"
  ],
  "brightness": [
    "Helligkeit",
    "Brightness",
    "السطوع",
    "Parlaklık",
    "Luminosité",
    "Brillo"
  ],
  "contrast": [
    "Kontrast",
    "Contrast",
    "التباين",
    "Kontrast",
    "Contraste",
    "Contraste"
  ],
  "saturation": [
    "Sättigung",
    "Saturation",
    "التشبع",
    "Doygunluk",
    "Saturation",
    "Saturación"
  ],
  "warmth": [
    "Wärme",
    "Warmth",
    "الدفء",
    "Sıcaklık",
    "Température",
    "Temperatura"
  ],
  "original": [
    "Original",
    "Original",
    "الأصل",
    "Orijinal",
    "Original",
    "Original"
  ],
  "warm": ["Warm", "Warm", "دافئ", "Sıcak", "Chaud", "Cálido"],
  "cool": ["Kühl", "Cool", "بارد", "Soğuk", "Froid", "Frío"],
  "blackWhite": [
    "Schwarz-Weiß",
    "Black & White",
    "أبيض وأسود",
    "Siyah Beyaz",
    "Noir et blanc",
    "Blanco y negro"
  ],
  "highContrast": [
    "Hoher Kontrast",
    "High Contrast",
    "تباين عالٍ",
    "Yüksek Kontrast",
    "Contraste élevé",
    "Contraste alto"
  ],
  "softFade": [
    "Sanft verblasst",
    "Soft Fade",
    "تلاشي ناعم",
    "Yumuşak Soluk",
    "Estompé doux",
    "Desvanecido suave"
  ],
  "vivid": ["Lebendig", "Vivid", "زاهٍ", "Canlı", "Vif", "Vívido"],
  "vintage": ["Vintage", "Vintage", "عتيق", "Nostaljik", "Vintage", "Vintage"],
  "sepia": ["Sepia", "Sepia", "بني داكن", "Sepya", "Sépia", "Sepia"],
  "matte": ["Matt", "Matte", "مطفي", "Mat", "Mat", "Mate"],
  "reset": [
    "Zurücksetzen",
    "Reset",
    "إعادة ضبط",
    "Sıfırla",
    "Réinitialiser",
    "Restablecer"
  ],
  "undo": ["Rückgängig", "Undo", "تراجع", "Geri al", "Annuler", "Deshacer"],
  "redo": ["Wiederholen", "Redo", "إعادة", "Yinele", "Rétablir", "Rehacer"],
  "Schließen": ["Schließen", "Close", "إغلاق", "Kapat", "Fermer", "Cerrar"],
  "Wohin soll deine Collage?": [
    "Wohin soll deine Collage?",
    "Where should your collage go?",
    "أين تريد إرسال التصميم؟",
    "Kolajınız nereye gitsin?",
    "Où envoyer votre collage ?",
    "¿Dónde quieres tu collage?"
  ],
  "Bildgröße": [
    "Bildgröße",
    "Image size",
    "حجم الصورة",
    "Görüntü boyutu",
    "Taille de l’image",
    "Tamaño de imagen"
  ],
  "Aktuell": ["Aktuell", "Current", "الحالي", "Mevcut", "Actuel", "Actual"],
  "Das Exportformat weicht deutlich ab. Bildausschnitte und Textpositionen werden für den Export neu eingepasst. Dein Projekt bleibt erhalten.":
      [
    "Das Exportformat weicht deutlich ab. Bildausschnitte und Textpositionen werden für den Export neu eingepasst. Dein Projekt bleibt erhalten.",
    "The export ratio differs significantly. Crops and text positions will be adapted for export. Your project is preserved.",
    "تختلف نسبة التصدير كثيراً. سيتم ضبط القص والنصوص للتصدير مع الحفاظ على المشروع.",
    "Dışa aktarma oranı farklı. Kırpma ve metin konumları uyarlanır. Projeniz korunur.",
    "Le format diffère beaucoup. Cadrages et textes seront adaptés à l’export. Votre projet est conservé.",
    "El formato es diferente. Los recortes y textos se adaptarán al exportar. Tu proyecto se conserva."
  ],
  "PNG exportiert den Hintergrund transparent.": [
    "PNG exportiert den Hintergrund transparent.",
    "PNG exports a transparent background.",
    "يصدّر PNG خلفية شفافة.",
    "PNG arka planı şeffaf dışa aktarır.",
    "PNG exporte un fond transparent.",
    "PNG exporta el fondo transparente."
  ],
  "JPEG ersetzt den transparenten Hintergrund durch Weiß.": [
    "JPEG ersetzt den transparenten Hintergrund durch Weiß.",
    "JPEG replaces transparency with white.",
    "يستبدل JPEG الشفافية بالأبيض.",
    "JPEG şeffaflığı beyazla değiştirir.",
    "JPEG remplace la transparence par du blanc.",
    "JPEG sustituye la transparencia por blanco."
  ],
  "Social-Media-Ziele öffnen die Ziel-App oder das Teilen-Menü. Wähle dort Story, Post oder Status und bestätige den Upload selbst.":
      [
    "Social-Media-Ziele öffnen die Ziel-App oder das Teilen-Menü. Wähle dort Story, Post oder Status und bestätige den Upload selbst.",
    "Social destinations open the app or share sheet. Choose Story, Post or Status there and confirm the upload yourself.",
    "تفتح وجهات التواصل التطبيق أو قائمة المشاركة. اختر القصة أو المنشور أو الحالة وأكّد الرفع بنفسك.",
    "Sosyal hedefler uygulamayı veya paylaşım menüsünü açar. Hikâye, gönderi veya durum seçip yüklemeyi onaylayın.",
    "Les destinations sociales ouvrent l’application ou le partage. Choisissez Story, Post ou Statut et confirmez l’envoi.",
    "Los destinos sociales abren la aplicación o el menú de compartir. Elige historia, publicación o estado y confirma la subida."
  ],
  "Bild wird vorbereitet …": [
    "Bild wird vorbereitet …",
    "Preparing image …",
    "جارٍ إعداد الصورة …",
    "Görüntü hazırlanıyor …",
    "Préparation de l’image…",
    "Preparando imagen…"
  ],
  "In Galerie speichern": [
    "In Galerie speichern",
    "Save to gallery",
    "حفظ في المعرض",
    "Galeriye kaydet",
    "Enregistrer dans la galerie",
    "Guardar en galería"
  ],
  "Bild vorbereiten & teilen": [
    "Bild vorbereiten & teilen",
    "Prepare & share image",
    "إعداد الصورة ومشاركتها",
    "Görüntüyü hazırla ve paylaş",
    "Préparer et partager l’image",
    "Preparar y compartir imagen"
  ],
  "Galerie speichern": [
    "Galerie speichern",
    "Save to gallery",
    "حفظ في المعرض",
    "Galeriye kaydet",
    "Enregistrer dans la galerie",
    "Guardar en galería"
  ],
  "Allgemein teilen": [
    "Allgemein teilen",
    "Share",
    "مشاركة",
    "Paylaş",
    "Partager",
    "Compartir"
  ],
  "Andere App": [
    "Andere App",
    "Other app",
    "تطبيق آخر",
    "Diğer uygulama",
    "Autre application",
    "Otra aplicación"
  ],
  "Quadrat": ["Quadrat", "Square", "مربع", "Kare", "Carré", "Cuadrado"],
  "Hochformat": [
    "Hochformat",
    "Portrait",
    "عمودي",
    "Dikey",
    "Portrait",
    "Vertical"
  ],
  "In Galerie gespeichert": [
    "In Galerie gespeichert",
    "Saved to gallery",
    "تم الحفظ في المعرض",
    "Galeriye kaydedildi",
    "Enregistré dans la galerie",
    "Guardado en galería"
  ],
  "Weiß": ["Weiß", "White", "أبيض", "Beyaz", "Blanc", "Blanco"],
  "Schwarz": ["Schwarz", "Black", "أسود", "Siyah", "Noir", "Negro"],
  "Creme": ["Creme", "Cream", "كريمي", "Krem", "Crème", "Crema"],
  "Blau": ["Blau", "Blue", "أزرق", "Mavi", "Bleu", "Azul"],
  "Rosa": ["Rosa", "Pink", "وردي", "Pembe", "Rose", "Rosa"],
  "Mint": ["Mint", "Mint", "نعناعي", "Nane", "Menthe", "Menta"],
  "Gelb": ["Gelb", "Yellow", "أصفر", "Sarı", "Jaune", "Amarillo"],
  "Rot": ["Rot", "Red", "أحمر", "Kırmızı", "Rouge", "Rojo"],
  "Reset": [
    "Reset",
    "Reset",
    "إعادة ضبط",
    "Sıfırla",
    "Réinitialiser",
    "Restablecer"
  ],
  "Hintergrund": [
    "Hintergrund",
    "Background",
    "الخلفية",
    "Arka plan",
    "Arrière-plan",
    "Fondo"
  ],
  "Rahmen": ["Rahmen", "Frame", "الإطار", "Çerçeve", "Cadre", "Marco"],
  "Schatten": ["Schatten", "Shadow", "الظل", "Gölge", "Ombre", "Sombra"],
  "Presets": [
    "Presets",
    "Presets",
    "أنماط جاهزة",
    "Hazır stiller",
    "Préréglages",
    "Preajustes"
  ],
  "Einfarbig": [
    "Einfarbig",
    "Solid",
    "لون واحد",
    "Düz renk",
    "Uni",
    "Color sólido"
  ],
  "Verlauf": ["Verlauf", "Gradient", "تدرج", "Gradyan", "Dégradé", "Degradado"],
  "Foto-Blur": [
    "Foto-Blur",
    "Photo blur",
    "تمويه الصورة",
    "Fotoğraf bulanıklığı",
    "Flou photo",
    "Desenfoque de foto"
  ],
  "Papier": ["Papier", "Paper", "ورق", "Kâğıt", "Papier", "Papel"],
  "Soft Grid": [
    "Soft Grid",
    "Soft Grid",
    "شبكة ناعمة",
    "Yumuşak ızgara",
    "Grille douce",
    "Cuadrícula suave"
  ],
  "Dots": ["Dots", "Dots", "نقاط", "Noktalar", "Points", "Puntos"],
  "Transparent": [
    "Transparent",
    "Transparent",
    "شفاف",
    "Şeffaf",
    "Transparent",
    "Transparente"
  ],
  "PNG bleibt transparent. JPEG erhält einen weißen Hintergrund. Das Schachbrett dient nur der Vorschau.":
      [
    "PNG bleibt transparent. JPEG erhält einen weißen Hintergrund. Das Schachbrett dient nur der Vorschau.",
    "PNG stays transparent. JPEG gets a white background. The checkerboard is only a preview.",
    "يبقى PNG شفافاً. يحصل JPEG على خلفية بيضاء. المربعات للمعاينة فقط.",
    "PNG şeffaf kalır. JPEG beyaz arka plan alır. Dama deseni yalnızca önizlemedir.",
    "PNG reste transparent. JPEG reçoit un fond blanc. Le damier sert uniquement d’aperçu.",
    "PNG conserva la transparencia. JPEG tiene fondo blanco. El tablero es solo una vista previa."
  ],
  "Hintergrundfarbe": [
    "Hintergrundfarbe",
    "Background color",
    "لون الخلفية",
    "Arka plan rengi",
    "Couleur de fond",
    "Color de fondo"
  ],
  "Zweite Farbe": [
    "Zweite Farbe",
    "Second color",
    "اللون الثاني",
    "İkinci renk",
    "Deuxième couleur",
    "Segundo color"
  ],
  "Verlaufsrichtung": [
    "Verlaufsrichtung",
    "Gradient direction",
    "اتجاه التدرج",
    "Gradyan yönü",
    "Direction du dégradé",
    "Dirección del degradado"
  ],
  "Kein Blur": [
    "Kein Blur",
    "No blur",
    "بدون تمويه",
    "Bulanıklık yok",
    "Sans flou",
    "Sin desenfoque"
  ],
  "Aktives Bild": [
    "Aktives Bild",
    "Active image",
    "الصورة النشطة",
    "Etkin görüntü",
    "Image active",
    "Imagen activa"
  ],
  "Bild": ["Bild", "Image", "صورة", "Görüntü", "Image", "Imagen"],
  "Fotos": ["Fotos", "Photos", "صور", "Fotoğraflar", "Photos", "Fotos"],
  "Blur-Stärke": [
    "Blur-Stärke",
    "Blur strength",
    "شدة التمويه",
    "Bulanıklık düzeyi",
    "Intensité du flou",
    "Intensidad de desenfoque"
  ],
  "Dunkler / heller": [
    "Dunkler / heller",
    "Darker / lighter",
    "أغمق / أفتح",
    "Daha koyu / açık",
    "Plus sombre / clair",
    "Más oscuro / claro"
  ],
  "Sättigung reduzieren": [
    "Sättigung reduzieren",
    "Reduce saturation",
    "تقليل التشبع",
    "Doygunluğu azalt",
    "Réduire la saturation",
    "Reducir saturación"
  ],
  "Die Quelle ist die gewählte Bildposition. Originaldateien bleiben unverändert.":
      [
    "Die Quelle ist die gewählte Bildposition. Originaldateien bleiben unverändert.",
    "The source is the selected photo position. Original files stay unchanged.",
    "المصدر هو موضع الصورة المختارة. تبقى الملفات الأصلية كما هي.",
    "Kaynak seçilen fotoğraf konumudur. Orijinal dosyalar değişmez.",
    "La source est la position choisie. Les fichiers originaux restent intacts.",
    "La fuente es la posición elegida. Los archivos originales no cambian."
  ],
  "Bildabstand": [
    "Bildabstand",
    "Photo spacing",
    "تباعد الصور",
    "Fotoğraf aralığı",
    "Espacement des photos",
    "Espaciado de fotos"
  ],
  "Außenrand": [
    "Außenrand",
    "Outer margin",
    "الهامش الخارجي",
    "Dış kenar",
    "Marge extérieure",
    "Margen exterior"
  ],
  "Eckenradius": [
    "Eckenradius",
    "Corner radius",
    "استدارة الزوايا",
    "Köşe yarıçapı",
    "Arrondi des coins",
    "Radio de esquinas"
  ],
  "Bildrahmen": [
    "Bildrahmen",
    "Photo frame",
    "إطار الصورة",
    "Fotoğraf çerçevesi",
    "Cadre photo",
    "Marco de foto"
  ],
  "Rahmenstärke": [
    "Rahmenstärke",
    "Frame width",
    "عرض الإطار",
    "Çerçeve kalınlığı",
    "Épaisseur du cadre",
    "Grosor del marco"
  ],
  "Direkt aneinanderliegende Bilder erhalten einen gemeinsamen Außenrahmen.": [
    "Direkt aneinanderliegende Bilder erhalten einen gemeinsamen Außenrahmen.",
    "Adjacent photos share one outer frame.",
    "تشترك الصور المتجاورة في إطار خارجي واحد.",
    "Bitişik fotoğraflar ortak dış çerçeve alır.",
    "Les photos adjacentes partagent un cadre extérieur.",
    "Las fotos contiguas comparten un marco exterior."
  ],
  "Schattenstärke": [
    "Schattenstärke",
    "Shadow opacity",
    "عتامة الظل",
    "Gölge opaklığı",
    "Opacité de l’ombre",
    "Opacidad de sombra"
  ],
  "Weichheit": [
    "Weichheit",
    "Softness",
    "النعومة",
    "Yumuşaklık",
    "Douceur",
    "Suavidad"
  ],
  "Presets ändern nur den Stil. Fotos, Reihenfolge und Texte bleiben erhalten.":
      [
    "Presets ändern nur den Stil. Fotos, Reihenfolge und Texte bleiben erhalten.",
    "Presets only change style. Photos, order and text stay unchanged.",
    "تغيّر الأنماط المظهر فقط. تبقى الصور والترتيب والنصوص.",
    "Hazır stiller yalnızca stili değiştirir. Fotoğraf, sıra ve metin korunur.",
    "Les préréglages changent le style. Photos, ordre et textes sont conservés.",
    "Los preajustes cambian el estilo. Se conservan fotos, orden y textos."
  ],
  "Die exportierte Datei wurde nicht gefunden.": [
    "Die exportierte Datei wurde nicht gefunden.",
    "The exported file was not found.",
    "لم يتم العثور على ملف التصدير.",
    "Dışa aktarılan dosya bulunamadı.",
    "Fichier exporté introuvable.",
    "No se encontró el archivo exportado."
  ],
  "Die exportierte Datei wurde nicht gefunden. Bitte erneut exportieren.": [
    "Die exportierte Datei wurde nicht gefunden. Bitte erneut exportieren.",
    "Exported file missing. Please export again.",
    "ملف التصدير مفقود. أعد التصدير.",
    "Dışa aktarılan dosya yok. Tekrar aktarın.",
    "Fichier exporté introuvable. Exportez à nouveau.",
    "Archivo exportado no encontrado. Vuelve a exportar."
  ],
  "Fotozugriff abgelehnt. Bitte erlaube das Speichern in den Systemeinstellungen.":
      [
    "Fotozugriff abgelehnt. Bitte erlaube das Speichern in den Systemeinstellungen.",
    "Photo access denied. Allow saving in system settings.",
    "تم رفض الوصول للصور. اسمح بالحفظ في إعدادات النظام.",
    "Fotoğraf erişimi reddedildi. Sistem ayarlarında kaydetmeye izin verin.",
    "Accès aux photos refusé. Autorisez l’enregistrement dans les paramètres système.",
    "Acceso a fotos denegado. Permite guardar en los ajustes del sistema."
  ],
  "Die Galerie ist auf diesem Gerät nicht verfügbar.": [
    "Die Galerie ist auf diesem Gerät nicht verfügbar.",
    "Gallery is unavailable on this device.",
    "المعرض غير متاح على هذا الجهاز.",
    "Galeri bu cihazda kullanılamıyor.",
    "La galerie est indisponible sur cet appareil.",
    "La galería no está disponible en este dispositivo."
  ],
  "Speichern fehlgeschlagen. Bitte prüfe den freien Speicher und versuche es erneut.":
      [
    "Speichern fehlgeschlagen. Bitte prüfe den freien Speicher und versuche es erneut.",
    "Saving failed. Check available storage and retry.",
    "فشل الحفظ. تحقق من المساحة وحاول مجدداً.",
    "Kaydetme başarısız. Boş alanı kontrol edip tekrar deneyin.",
    "Échec de l’enregistrement. Vérifiez l’espace libre et réessayez.",
    "No se pudo guardar. Revisa el espacio libre e inténtalo de nuevo."
  ],
  "Galerie speichern wird auf diesem Gerät nicht unterstützt.": [
    "Galerie speichern wird auf diesem Gerät nicht unterstützt.",
    "Saving to gallery is unsupported on this device.",
    "الحفظ في المعرض غير مدعوم على هذا الجهاز.",
    "Bu cihazda galeriye kaydetme desteklenmiyor.",
    "L’enregistrement en galerie n’est pas pris en charge.",
    "Este dispositivo no admite guardar en galería."
  ],
  "Wähle die Ziel-App im Teilen-Menü. Den Upload bestätigst du dort selbst.": [
    "Wähle die Ziel-App im Teilen-Menü. Den Upload bestätigst du dort selbst.",
    "Choose the target app in the share sheet and confirm the upload there.",
    "اختر التطبيق في قائمة المشاركة وأكّد الرفع هناك.",
    "Paylaşım menüsünde hedef uygulamayı seçip yüklemeyi onaylayın.",
    "Choisissez l’application dans le partage et confirmez l’envoi.",
    "Elige la aplicación en el menú de compartir y confirma la subida."
  ],
  "Ziel-App nicht installiert. Wähle eine andere App im Teilen-Menü.": [
    "Ziel-App nicht installiert. Wähle eine andere App im Teilen-Menü.",
    "Target app not installed. Choose another app in the share sheet.",
    "التطبيق غير مثبت. اختر تطبيقاً آخر من قائمة المشاركة.",
    "Hedef uygulama yüklü değil. Paylaşım menüsünde başka bir uygulama seçin.",
    "Application cible non installée. Choisissez-en une autre dans le partage.",
    "La aplicación no está instalada. Elige otra en el menú de compartir."
  ],
  "Das Teilen-Menü konnte nicht geöffnet werden. Du kannst das Bild in der Galerie speichern.":
      [
    "Das Teilen-Menü konnte nicht geöffnet werden. Du kannst das Bild in der Galerie speichern.",
    "Could not open the share sheet. You can save the image to the gallery.",
    "تعذر فتح قائمة المشاركة. يمكنك حفظ الصورة في المعرض.",
    "Paylaşım menüsü açılamadı. Görüntüyü galeriye kaydedebilirsiniz.",
    "Impossible d’ouvrir le partage. Vous pouvez enregistrer l’image dans la galerie.",
    "No se pudo abrir el menú de compartir. Puedes guardar la imagen en la galería."
  ],
  'Hero links': [
    'Hero links',
    'Hero left',
    'الصورة الرئيسية يساراً',
    'Ana fotoğraf solda',
    'Photo principale à gauche',
    'Foto principal a la izquierda'
  ],
  'Hero oben': [
    'Hero oben',
    'Hero top',
    'الصورة الرئيسية أعلى',
    'Ana fotoğraf üstte',
    'Photo principale en haut',
    'Foto principal arriba'
  ],
  'Versetzt': [
    'Versetzt',
    'Staggered',
    'متدرج',
    'Kaydırılmış',
    'Décalé',
    'Escalonado'
  ],
  '1 Bild': [
    '1 Bild',
    '1 image',
    'صورة واحدة',
    '1 görüntü',
    '1 image',
    '1 imagen'
  ],
  'Ausgewogene Reihen': [
    'Ausgewogene Reihen',
    'Balanced rows',
    'صفوف متوازنة',
    'Dengeli satırlar',
    'Rangées équilibrées',
    'Filas equilibradas'
  ],
  '2 nebeneinander': [
    '2 nebeneinander',
    '2 side by side',
    'صورتان متجاورتان',
    '2 yan yana',
    '2 côte à côte',
    '2 en paralelo'
  ],
  '2 übereinander': [
    '2 übereinander',
    '2 stacked',
    'صورتان فوق بعضهما',
    '2 üst üste',
    '2 superposées',
    '2 apiladas'
  ],
  '3 Spalten': [
    '3 Spalten',
    '3 columns',
    '٣ أعمدة',
    '3 sütun',
    '3 colonnes',
    '3 columnas'
  ],
  '3 Reihen': [
    '3 Reihen',
    '3 rows',
    '٣ صفوف',
    '3 satır',
    '3 rangées',
    '3 filas'
  ],
  "customLayout": [
    "Eigenes Layout",
    "Custom layout",
    "تخطيط مخصص",
    "Özel düzen",
    "Disposition personnalisée",
    "Diseño personalizado"
  ],
  "editCustomLayout": [
    "Layout bearbeiten",
    "Edit layout",
    "تعديل التخطيط",
    "Düzeni düzenle",
    "Modifier la disposition",
    "Editar diseño"
  ],
  "saveCustomLayout": [
    "Als Layout speichern",
    "Save as layout",
    "حفظ كتخطيط",
    "Düzen olarak kaydet",
    "Enregistrer comme disposition",
    "Guardar como diseño"
  ],
  "myCustomLayouts": [
    "Eigene Layouts",
    "My layouts",
    "تخطيطاتي",
    "Düzenlerim",
    "Mes dispositions",
    "Mis diseños"
  ],
  "customLayoutName": [
    "Layoutname",
    "Layout name",
    "اسم التخطيط",
    "Düzen adı",
    "Nom de la disposition",
    "Nombre del diseño"
  ],
  "customLayoutSaved": [
    "Layout gespeichert",
    "Layout saved",
    "تم حفظ التخطيط",
    "Düzen kaydedildi",
    "Disposition enregistrée",
    "Diseño guardado"
  ],
  "customLayoutSaveFailed": [
    "Layout konnte nicht gespeichert werden. Bitte erneut versuchen.",
    "Could not save layout. Please try again.",
    "تعذر حفظ التخطيط. حاول مرة أخرى.",
    "Düzen kaydedilemedi. Tekrar deneyin.",
    "Impossible d’enregistrer la disposition. Réessayez.",
    "No se pudo guardar el diseño. Inténtalo de nuevo."
  ],
  "customLayoutLoadFailed": [
    "Eigene Layouts konnten nicht geladen werden. Erneut versuchen.",
    "Could not load custom layouts. Retry.",
    "تعذر تحميل التخطيطات المخصصة. أعد المحاولة.",
    "Özel düzenler yüklenemedi. Tekrar dene.",
    "Impossible de charger les dispositions. Réessayer.",
    "No se pudieron cargar los diseños. Reintentar."
  ],
  "noCustomLayouts": [
    "Noch keine eigenen Layouts für diese Fotoanzahl.",
    "No custom layouts for this photo count yet.",
    "لا توجد تخطيطات مخصصة لهذا العدد من الصور بعد.",
    "Bu fotoğraf sayısı için henüz özel düzen yok.",
    "Aucune disposition pour ce nombre de photos.",
    "Aún no hay diseños para esta cantidad de fotos."
  ],
  "layoutBuilderHint": [
    "Tippe auf eine Zelle. Ziehe die Griffe oder nutze die Regler darunter. Fertig übernimmt deine Änderungen.",
    "Tap a cell. Drag the handles or use the sliders below. Done applies your changes.",
    "اضغط على خلية. اسحب المقابض أو استخدم أشرطة التمرير أدناه. اضغط تم لتطبيق التغييرات.",
    "Bir hücreye dokunun. Tutamaçları sürükleyin veya aşağıdaki kaydırıcıları kullanın. Bitti değişiklikleri uygular.",
    "Touchez une cellule. Déplacez les poignées ou utilisez les curseurs. Terminé applique les modifications.",
    "Toca una celda. Arrastra los controles o usa los deslizadores. Listo aplica los cambios."
  ],
  "layoutBuilderAdjusted": [
    "Das bisherige Layout enthält Leerflächen oder zu kleine Zellen. Als Start wurde ein passendes, lückenloses Layout gewählt.",
    "The previous layout has empty areas or cells that are too small. A compatible layout without gaps was selected as a starting point.",
    "التخطيط السابق يحتوي على فراغات أو خلايا صغيرة جداً. تم اختيار تخطيط مناسب دون فراغات للبدء.",
    "Önceki düzende boşluklar veya çok küçük hücreler var. Başlangıç için boşluksuz uygun bir düzen seçildi.",
    "La disposition précédente contient des vides ou des cellules trop petites. Une disposition adaptée sans vides a été choisie.",
    "El diseño anterior tiene huecos o celdas demasiado pequeñas. Se eligió un diseño compatible sin huecos para empezar."
  ],
  "layoutBuilderStart": [
    "Startlayout",
    "Starting layout",
    "تخطيط البداية",
    "Başlangıç düzeni",
    "Disposition de départ",
    "Diseño inicial"
  ],
  "layoutBuilderCell": [
    "Ausgewählte Zelle",
    "Selected cell",
    "الخلية المحددة",
    "Seçili hücre",
    "Cellule sélectionnée",
    "Celda seleccionada"
  ],
  "layoutBuilderMinimum": [
    "Mindestgröße: 12 % je Achse. Außenkanten bleiben bündig. Abstände und Rahmen folgen deinem Stil.",
    "Minimum size: 12% on each axis. Outer edges stay aligned. Spacing and frames follow your style.",
    "الحد الأدنى للحجم ١٢٪ لكل محور. تبقى الحواف الخارجية متراصة. التباعد والإطارات تتبع النمط المختار.",
    "Her eksende en az %12. Dış kenarlar hizalı kalır. Aralıklar ve çerçeveler stilinize uyar.",
    "Minimum : 12 % par axe. Les bords extérieurs restent alignés. Espacements et cadres suivent votre style.",
    "Mínimo: 12 % por eje. Los bordes exteriores quedan alineados. Los espacios y marcos siguen tu estilo."
  ],
  "layoutBuilderNoDividers": [
    "Diese Zelle hat keine verschiebbaren Trennlinien.",
    "This cell has no movable dividers.",
    "لا توجد فواصل قابلة للتحريك لهذه الخلية.",
    "Bu hücrede taşınabilir ayırıcı yok.",
    "Cette cellule n’a pas de séparation déplaçable.",
    "Esta celda no tiene separadores móviles."
  ],
  "layoutBuilderVertical": [
    "Vertikale Trennlinie",
    "Vertical divider",
    "فاصل عمودي",
    "Dikey ayırıcı",
    "Séparation verticale",
    "Separador vertical"
  ],
  "layoutBuilderHorizontal": [
    "Horizontale Trennlinie",
    "Horizontal divider",
    "فاصل أفقي",
    "Yatay ayırıcı",
    "Séparation horizontale",
    "Separador horizontal"
  ],
  "stickers": [
    "Sticker",
    "Stickers",
    "ملصقات",
    "Çıkartmalar",
    "Autocollants",
    "Pegatinas"
  ],
  "includeStickers": [
    "Sticker übernehmen",
    "Include stickers",
    "تضمين الملصقات",
    "Çıkartmaları dahil et",
    "Inclure les autocollants",
    "Incluir pegatinas"
  ],
  "stCategory_emojis": [
    "Emojis",
    "Emojis",
    "رموز تعبيرية",
    "Emojiler",
    "Émojis",
    "Emojis"
  ],
  "stCategory_shapes": [
    "Formen",
    "Shapes",
    "أشكال",
    "Şekiller",
    "Formes",
    "Formas"
  ],
  "stCategory_arrows": [
    "Pfeile",
    "Arrows",
    "أسهم",
    "Oklar",
    "Flèches",
    "Flechas"
  ],
  "stCategory_hearts": [
    "Herzen/Sterne",
    "Hearts/Stars",
    "قلوب ونجوم",
    "Kalpler/Yıldızlar",
    "Cœurs/Étoiles",
    "Corazones/Estrellas"
  ],
  "stCategory_story": [
    "Social/Story",
    "Social/Story",
    "قصص وتواصل",
    "Sosyal/Hikâye",
    "Réseaux/Story",
    "Redes/Historia"
  ],
  "stCategory_labels": [
    "Datum/Ort",
    "Date/Place",
    "تاريخ ومكان",
    "Tarih/Yer",
    "Date/Lieu",
    "Fecha/Lugar"
  ],
  "stHeart": ["Herz", "Heart", "قلب", "Kalp", "Cœur", "Corazón"],
  "stSparkles": [
    "Glitzer",
    "Sparkles",
    "بريق",
    "Parıltı",
    "Étincelles",
    "Destellos"
  ],
  "stStar": ["Stern", "Star", "نجمة", "Yıldız", "Étoile", "Estrella"],
  "stPin": ["Pin", "Pin", "دبوس", "İşaretçi", "Repère", "Marcador"],
  "stSmile": ["Lächeln", "Smile", "ابتسامة", "Gülümseme", "Sourire", "Sonrisa"],
  "stFire": ["Feuer", "Fire", "نار", "Ateş", "Feu", "Fuego"],
  "stCircle": ["Kreis", "Circle", "دائرة", "Daire", "Cercle", "Círculo"],
  "stRectangle": [
    "Rechteck",
    "Rectangle",
    "مستطيل",
    "Dikdörtgen",
    "Rectangle",
    "Rectángulo"
  ],
  "stRounded": [
    "Abgerundet",
    "Rounded",
    "مستطيل مستدير",
    "Yuvarlatılmış",
    "Arrondi",
    "Redondeado"
  ],
  "stLine": ["Linie", "Line", "خط", "Çizgi", "Ligne", "Línea"],
  "stBubble": [
    "Sprechblase",
    "Speech bubble",
    "فقاعة كلام",
    "Konuşma balonu",
    "Bulle",
    "Bocadillo"
  ],
  "stLeft": ["Links", "Left", "يسار", "Sol", "Gauche", "Izquierda"],
  "stRight": ["Rechts", "Right", "يمين", "Sağ", "Droite", "Derecha"],
  "stUp": ["Oben", "Up", "أعلى", "Yukarı", "Haut", "Arriba"],
  "stDown": ["Unten", "Down", "أسفل", "Aşağı", "Bas", "Abajo"],
  "stCamera": [
    "Kamera",
    "Camera",
    "كاميرا",
    "Kamera",
    "Appareil photo",
    "Cámara"
  ],
  "stParty": ["Party", "Party", "احتفال", "Kutlama", "Fête", "Fiesta"],
  "stWow": ["WOW!", "WOW!", "واو!", "VAY!", "WAOUH !", "¡GUAU!"],
  "stDate": ["Datum", "Date", "التاريخ", "Tarih", "Date", "Fecha"],
  "stPlace": ["Mein Ort", "My place", "مكاني", "Yerim", "Mon lieu", "Mi lugar"],
  "stHint": [
    "Ziehen zum Verschieben, mit zwei Fingern skalieren und drehen. Zum Bearbeiten doppelt antippen oder auswählen und „Sticker bearbeiten“ öffnen.",
    "Drag to move; use two fingers to resize and rotate. Double-tap to edit, or select and open “Edit sticker”.",
    "اسحب للتحريك واستخدم إصبعين لتغيير الحجم والتدوير. انقر مرتين للتعديل أو حدد الملصق وافتح تعديل الملصق.",
    "Taşımak için sürükleyin; boyut ve dönüş için iki parmak kullanın. Düzenlemek için çift dokunun veya seçip Çıkartmayı düzenle seçeneğini açın.",
    "Glissez pour déplacer ; utilisez deux doigts pour redimensionner et tourner. Touchez deux fois pour modifier, ou sélectionnez puis ouvrez Modifier l’autocollant.",
    "Arrastra para mover; usa dos dedos para cambiar tamaño y girar. Toca dos veces para editar o selecciona y abre Editar pegatina."
  ],
  "stOnCanvas": [
    "Sticker auf der Collage",
    "Stickers on canvas",
    "ملصقات التصميم",
    "Kolajdaki çıkartmalar",
    "Autocollants du collage",
    "Pegatinas del collage"
  ],
  "stEdit": [
    "Sticker bearbeiten",
    "Edit sticker",
    "تعديل الملصق",
    "Çıkartmayı düzenle",
    "Modifier l’autocollant",
    "Editar pegatina"
  ],
  "stLabelText": [
    "Label-Text",
    "Label text",
    "نص الملصق",
    "Etiket metni",
    "Texte de l’étiquette",
    "Texto de etiqueta"
  ],
  "stSize": ["Größe", "Size", "الحجم", "Boyut", "Taille", "Tamaño"],
  "stRotation": [
    "Drehung",
    "Rotation",
    "الدوران",
    "Döndürme",
    "Rotation",
    "Rotación"
  ],
  "stOpacity": [
    "Deckkraft",
    "Opacity",
    "التعتيم",
    "Opaklık",
    "Opacité",
    "Opacidad"
  ],
  "stColor": ["Farbe", "Color", "اللون", "Renk", "Couleur", "Color"],
  "stBackground": [
    "Sticker-Hintergrund",
    "Sticker background",
    "خلفية الملصق",
    "Çıkartma arka planı",
    "Fond de l’autocollant",
    "Fondo de pegatina"
  ],
  "stNoBackground": [
    "Ohne Hintergrund",
    "No background",
    "بدون خلفية",
    "Arka plan yok",
    "Sans fond",
    "Sin fondo"
  ],
  "stEmojiColor": [
    "Emojis behalten ihre Gerätefarben.",
    "Emojis retain their device colors.",
    "تحتفظ الرموز التعبيرية بألوان الجهاز.",
    "Emojiler cihaz renklerini korur.",
    "Les émojis gardent les couleurs de l’appareil.",
    "Los emojis conservan los colores del dispositivo."
  ],
  "stDuplicate": [
    "Duplizieren",
    "Duplicate",
    "تكرار",
    "Çoğalt",
    "Dupliquer",
    "Duplicar"
  ],
  "stFront": [
    "Ganz nach vorne",
    "Bring to front",
    "إلى المقدمة",
    "En öne getir",
    "Au premier plan",
    "Traer al frente"
  ],
  "stBack": [
    "Ganz nach hinten",
    "Send to back",
    "إلى الخلف",
    "En arkaya gönder",
    "À l’arrière-plan",
    "Enviar al fondo"
  ],
  "stColor0": ["Weiß", "White", "أبيض", "Beyaz", "Blanc", "Blanco"],
  "stColor1": ["Schwarz", "Black", "أسود", "Siyah", "Noir", "Negro"],
  "stColor2": ["Pink", "Pink", "وردي", "Pembe", "Rose", "Rosa"],
  "stColor3": ["Gelb", "Yellow", "أصفر", "Sarı", "Jaune", "Amarillo"],
  "stColor4": ["Grün", "Green", "أخضر", "Yeşil", "Vert", "Verde"],
  "stColor5": ["Blau", "Blue", "أزرق", "Mavi", "Bleu", "Azul"],
  "stColor6": ["Violett", "Purple", "بنفسجي", "Mor", "Violet", "Violeta"],
  "archiveImport": [
    "Projekt importieren",
    "Import project",
    "استيراد مشروع",
    "Projeyi içe aktar",
    "Importer un projet",
    "Importar proyecto"
  ],
  "archiveExport": [
    "Projekt exportieren",
    "Export project",
    "تصدير المشروع",
    "Projeyi dışa aktar",
    "Exporter le projet",
    "Exportar proyecto"
  ],
  "archiveWorking": [
    "Projektdatei wird verarbeitet …",
    "Processing project file…",
    "جارٍ معالجة ملف المشروع…",
    "Proje dosyası işleniyor…",
    "Traitement du fichier projet…",
    "Procesando archivo de proyecto…"
  ],
  "archiveImported": [
    "Projekt importiert",
    "Project imported",
    "تم استيراد المشروع",
    "Proje içe aktarıldı",
    "Projet importé",
    "Proyecto importado"
  ],
  "archiveCancelled": [
    "Import abgebrochen",
    "Import cancelled",
    "تم إلغاء الاستيراد",
    "İçe aktarma iptal edildi",
    "Importation annulée",
    "Importación cancelada"
  ],
  "archiveWrongFile": [
    "Bitte eine .piclayout-Projektdatei wählen.",
    "Please choose a .piclayout project file.",
    "يرجى اختيار ملف مشروع بامتداد .piclayout.",
    "Lütfen bir .piclayout proje dosyası seçin.",
    "Choisissez un fichier projet .piclayout.",
    "Elige un archivo de proyecto .piclayout."
  ],
  "archiveInvalid": [
    "Die Projektdatei ist beschädigt oder hat ein ungültiges Format.",
    "The project file is damaged or has an invalid format.",
    "ملف المشروع تالف أو تنسيقه غير صالح.",
    "Proje dosyası bozuk veya biçimi geçersiz.",
    "Le fichier projet est endommagé ou son format est invalide.",
    "El archivo de proyecto está dañado o su formato no es válido."
  ],
  "archiveVersionError": [
    "Diese Projektversion wird nicht unterstützt. Bitte PicLayout aktualisieren.",
    "This project version is not supported. Please update PicLayout.",
    "إصدار المشروع غير مدعوم. يرجى تحديث PicLayout.",
    "Bu proje sürümü desteklenmiyor. Lütfen PicLayout uygulamasını güncelleyin.",
    "Cette version du projet n’est pas prise en charge. Mettez PicLayout à jour.",
    "Esta versión del proyecto no es compatible. Actualiza PicLayout."
  ],
  "archiveMissingImages": [
    "Benötigte Projektbilder fehlen oder sind nicht im privaten Projektspeicher verfügbar.",
    "Required project images are missing or unavailable in private project storage.",
    "صور المشروع المطلوبة مفقودة أو غير متاحة في التخزين الخاص للمشروع.",
    "Gerekli proje görselleri eksik veya özel proje depolamasında bulunamıyor.",
    "Des images nécessaires manquent ou sont indisponibles dans le stockage privé du projet.",
    "Faltan imágenes necesarias o no están disponibles en el almacenamiento privado del proyecto."
  ],
  "archiveNoSpace": [
    "Nicht genügend Speicherplatz. Bitte Speicher freigeben und erneut versuchen.",
    "Not enough storage. Free up space and try again.",
    "مساحة التخزين غير كافية. حرر مساحة وحاول مجددًا.",
    "Yeterli depolama alanı yok. Alan açıp yeniden deneyin.",
    "Espace insuffisant. Libérez de l’espace et réessayez.",
    "No hay suficiente espacio. Libera espacio e inténtalo de nuevo."
  ],
  "archiveStorageError": [
    "Projektdatei konnte nicht gelesen oder gespeichert werden. Bitte Speicher und Zugriff prüfen.",
    "Could not read or save the project file. Check storage and access.",
    "تعذرت قراءة ملف المشروع أو حفظه. تحقق من التخزين وإمكانية الوصول.",
    "Proje dosyası okunamadı veya kaydedilemedi. Depolamayı ve erişimi kontrol edin.",
    "Impossible de lire ou enregistrer le projet. Vérifiez le stockage et les accès.",
    "No se pudo leer o guardar el proyecto. Comprueba el almacenamiento y el acceso."
  ],
  "archiveTooLarge": [
    "Projektdatei zu groß: maximal 128 MB insgesamt, 32 MB je Bild und 40 Megapixel je Foto.",
    "Project too large: maximum 128 MB total, 32 MB per image and 40 megapixels per photo.",
    "المشروع كبير جدًا: الحد 128 ميغابايت إجمالًا و32 ميغابايت و40 ميغابكسل لكل صورة.",
    "Proje çok büyük: toplam en fazla 128 MB, görsel başına 32 MB ve fotoğraf başına 40 megapiksel.",
    "Projet trop volumineux : 128 Mo au total, 32 Mo et 40 mégapixels par photo au maximum.",
    "Proyecto demasiado grande: máximo 128 MB en total, 32 MB y 40 megapíxeles por foto."
  ],
  "archivePickerError": [
    "Dateiauswahl nicht verfügbar. Bitte erneut versuchen.",
    "File picker unavailable. Please try again.",
    "اختيار الملفات غير متاح. حاول مجددًا.",
    "Dosya seçici kullanılamıyor. Lütfen yeniden deneyin.",
    "Sélection de fichier indisponible. Réessayez.",
    "Selector de archivos no disponible. Inténtalo de nuevo."
  ],
  "archiveShareError": [
    "Projektdatei konnte nicht geteilt werden. Bitte erneut versuchen.",
    "Could not share the project file. Please try again.",
    "تعذرت مشاركة ملف المشروع. حاول مجددًا.",
    "Proje dosyası paylaşılamadı. Lütfen yeniden deneyin.",
    "Impossible de partager le projet. Réessayez.",
    "No se pudo compartir el proyecto. Inténtalo de nuevo."
  ],
};
