// German, English, Arabic, Turkish, French, Spanish.
const freeformTranslations = <String, List<String>>{
  'ffTitle': [
    'Freie Collage',
    'Freeform Collage',
    'كولاج حر',
    'Serbest Kolaj',
    'Collage libre',
    'Collage libre'
  ],
  'ffFrames': ['Rahmen', 'frames', 'إطارات', 'çerçeve', 'cadres', 'marcos'],
  'ffFrame': ['Rahmen', 'Frame', 'إطار', 'Çerçeve', 'Cadre', 'Marco'],
  'ffAddPhotos': [
    'Fotos hinzufügen',
    'Add photos',
    'إضافة صور',
    'Fotoğraf ekle',
    'Ajouter des photos',
    'Añadir fotos'
  ],
  'ffFill': [
    'Foto einsetzen / ersetzen',
    'Fill / replace photo',
    'إضافة صورة أو استبدالها',
    'Fotoğraf ekle / değiştir',
    'Insérer / remplacer la photo',
    'Insertar / reemplazar foto'
  ],
  'ffRemovePhoto': [
    'Foto entfernen, Rahmen behalten',
    'Remove photo, keep frame',
    'إزالة الصورة مع إبقاء الإطار',
    'Fotoğrafı kaldır, çerçeveyi tut',
    'Retirer la photo, garder le cadre',
    'Quitar foto, conservar marco'
  ],
  'ffSwap': [
    'Fotos tauschen / verschieben',
    'Swap / move photos',
    'تبديل الصور أو نقلها',
    'Fotoğrafları değiştir / taşı',
    'Échanger / déplacer les photos',
    'Intercambiar / mover fotos'
  ],
  'ffFront': [
    'Ganz nach vorn',
    'Bring to front',
    'إحضار إلى المقدمة',
    'En öne getir',
    'Mettre au premier plan',
    'Traer al frente'
  ],
  'ffBack': [
    'Ganz nach hinten',
    'Send to back',
    'إرسال إلى الخلف',
    'En arkaya gönder',
    'Mettre à l’arrière-plan',
    'Enviar al fondo'
  ],
  'ffResetFrame': [
    'Rahmen zurücksetzen',
    'Reset frame',
    'إعادة ضبط الإطار',
    'Çerçeveyi sıfırla',
    'Réinitialiser le cadre',
    'Restablecer marco'
  ],
  'ffCenter': [
    'Auf Leinwand zentrieren',
    'Center on canvas',
    'توسيط على اللوحة',
    'Tuvalde ortala',
    'Centrer sur la toile',
    'Centrar en el lienzo'
  ],
  'ffFitCanvas': [
    'Rahmen an Leinwand anpassen',
    'Fit frame to canvas',
    'ملاءمة الإطار للوحة',
    'Çerçeveyi tuvale sığdır',
    'Adapter le cadre à la toile',
    'Ajustar marco al lienzo'
  ],
  'ffAspectLock': [
    'Seitenverhältnis sperren',
    'Lock aspect ratio',
    'قفل نسبة الأبعاد',
    'En boy oranını kilitle',
    'Verrouiller les proportions',
    'Bloquear proporciones'
  ],
  'ffShadow': [
    'Rahmenschatten',
    'Frame shadow',
    'ظل الإطار',
    'Çerçeve gölgesi',
    'Ombre du cadre',
    'Sombra del marco'
  ],
  'ffName': [
    'Rahmenname',
    'Frame name',
    'اسم الإطار',
    'Çerçeve adı',
    'Nom du cadre',
    'Nombre del marco'
  ],
  'ffExpand': [
    'Groß bearbeiten',
    'Expand editor',
    'توسيع المحرر',
    'Düzenleyiciyi büyüt',
    'Agrandir l’éditeur',
    'Ampliar editor'
  ],
  'ffReorder': [
    'Reihenfolge ändern',
    'Reorder',
    'إعادة ترتيب',
    'Yeniden sırala',
    'Réorganiser',
    'Reordenar'
  ],
  'ffMapTitle': [
    'Fotos den Rahmen zuordnen',
    'Map photos to frames',
    'توزيع الصور على الإطارات',
    'Fotoğrafları çerçevelere yerleştir',
    'Associer les photos aux cadres',
    'Asignar fotos a marcos'
  ],
  'ffMapHint': [
    'Ziehen zum Sortieren. Das Design wird ersetzt. Übrige Rahmen bleiben leer; zusätzliche Fotos bleiben im Projekt.',
    'Drag to reorder. This replaces the design. Extra frames stay empty; extra photos stay in the project.',
    'اسحب لإعادة الترتيب. سيُستبدل التصميم. تبقى الإطارات الزائدة فارغة والصور الإضافية في المشروع.',
    'Sıralamak için sürükleyin. Tasarım değiştirilir. Fazla çerçeveler boş, fazla fotoğraflar projede kalır.',
    'Faites glisser pour réordonner. Le design sera remplacé. Les cadres en trop restent vides et les photos supplémentaires restent dans le projet.',
    'Arrastra para ordenar. Se reemplazará el diseño. Los marcos sobrantes quedan vacíos y las fotos adicionales permanecen en el proyecto.'
  ],
  'ffGestureHint': [
    'Tippen: Rahmen wählen. Ziehen: bewegen. Zwei Finger: Größe und Drehung. Doppeltippen: Bildausschnitt.',
    'Tap to select. Drag to move. Two fingers resize and rotate. Double-tap to crop.',
    'انقر للاختيار واسحب للتحريك. استخدم إصبعين للتحجيم والتدوير. انقر مرتين لاقتصاص الصورة.',
    'Seçmek için dokun, taşımak için sürükle. İki parmakla boyutlandır ve döndür. Kırpmak için çift dokun.',
    'Touchez pour sélectionner, glissez pour déplacer. Deux doigts pour redimensionner et pivoter. Double touchez pour recadrer.',
    'Toca para seleccionar y arrastra para mover. Dos dedos cambian tamaño y rotación. Toca dos veces para recortar.'
  ],
  'ffCropHint': [
    'Bildausschnitt: Foto ziehen oder mit zwei Fingern zoomen. Der Rahmen bleibt stehen.',
    'Crop mode: drag or pinch the photo. The frame stays in place.',
    'وضع الاقتصاص: اسحب الصورة أو كبّرها بإصبعين. يبقى الإطار ثابتًا.',
    'Kırpma: fotoğrafı sürükle veya iki parmakla yakınlaştır. Çerçeve sabit kalır.',
    'Recadrage : glissez ou pincez la photo. Le cadre reste fixe.',
    'Recorte: arrastra o pellizca la foto. El marco permanece fijo.'
  ],
  'ffLimit': [
    'Maximal 20 Rahmen und 20 Quellfotos. Entferne zuerst einen Rahmen oder ein unbenutztes Foto.',
    'Up to 20 frames and 20 source photos. Remove a frame or unused photo first.',
    'الحد الأقصى 20 إطارًا و20 صورة مصدر. أزل إطارًا أو صورة غير مستخدمة أولًا.',
    'En fazla 20 çerçeve ve 20 kaynak fotoğraf. Önce bir çerçeveyi veya kullanılmayan fotoğrafı kaldırın.',
    '20 cadres et 20 photos source maximum. Retirez d’abord un cadre ou une photo inutilisée.',
    'Máximo 20 marcos y 20 fotos de origen. Quita primero un marco o una foto sin usar.'
  ],
  'ffGridLimit': [
    'Standard- und Editorial-Layouts benötigen 1–12 Fotos.',
    'Standard and editorial layouts require 1–12 photos.',
    'تتطلب التخطيطات القياسية والتحريرية من صورة إلى 12 صورة.',
    'Standart ve editoryal düzenler 1–12 fotoğraf gerektirir.',
    'Les mises en page standard et éditoriales nécessitent 1 à 12 photos.',
    'Los diseños estándar y editoriales requieren entre 1 y 12 fotos.'
  ],
  'ffStory9': [
    'Story-Mosaik 9',
    'Story Mosaic 9',
    'فسيفساء قصة 9',
    'Hikâye Mozaiği 9',
    'Mosaïque Story 9',
    'Mosaico Story 9'
  ],
  'ffStory12': [
    'Story-Mosaik 12',
    'Story Mosaic 12',
    'فسيفساء قصة 12',
    'Hikâye Mozaiği 12',
    'Mosaïque Story 12',
    'Mosaico Story 12'
  ],
  'ffStory15': [
    'Story-Mosaik 15',
    'Story Mosaic 15',
    'فسيفساء قصة 15',
    'Hikâye Mozaiği 15',
    'Mosaïque Story 15',
    'Mosaico Story 15'
  ],
  'ffCanvas': [
    'Freie Leinwand',
    'Free Canvas',
    'لوحة حرة',
    'Serbest Tuval',
    'Toile libre',
    'Lienzo libre'
  ],
  'ffScrapbook': [
    'Erinnerungsalbum',
    'Scrapbook',
    'ألبوم ذكريات',
    'Anı Defteri',
    'Album de souvenirs',
    'Álbum de recuerdos'
  ],
  'ffGallery': [
    'Klare Galerie',
    'Clean Gallery',
    'معرض منتظم',
    'Düzenli Galeri',
    'Galerie épurée',
    'Galería ordenada'
  ],
  'edMode_freeform': [
    'Freie Collage',
    'Freeform Collage',
    'كولاج حر',
    'Serbest Kolaj',
    'Collage libre',
    'Collage libre'
  ],
};
