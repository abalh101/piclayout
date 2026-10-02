// Order: German, English, Arabic, Turkish, French, Spanish.
const translations = <String, List<String>>{
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
};
