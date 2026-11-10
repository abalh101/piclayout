// German, English, Arabic, Turkish, French, Spanish.
const editorialTranslations = <String, List<String>>{
  'edDesign': ['Design', 'Design', 'تصميم', 'Tasarım', 'Design', 'Diseño'],
  'edLayers': ['Ebenen', 'Layers', 'الطبقات', 'Katmanlar', 'Calques', 'Capas'],
  'edPresets': [
    'Designvorlagen',
    'Design presets',
    'قوالب التصميم',
    'Tasarım şablonları',
    'Modèles de design',
    'Plantillas de diseño'
  ],
  'edPage': ['Seite', 'Page', 'الصفحة', 'Sayfa', 'Page', 'Página'],
  'edStandard': [
    'Standardlayout',
    'Standard layout',
    'تخطيط قياسي',
    'Standart düzen',
    'Mise en page standard',
    'Diseño estándar'
  ],
  'edBlank': [
    'Leeres Design starten',
    'Start from blank',
    'البدء بتصميم فارغ',
    'Boş tasarımla başla',
    'Créer un design vide',
    'Empezar en blanco'
  ],
  'edResume': [
    'Design wieder anzeigen',
    'Show design again',
    'إظهار التصميم مجددًا',
    'Tasarımı tekrar göster',
    'Réafficher le design',
    'Mostrar diseño de nuevo'
  ],
  'edWeek': [
    'Eine Woche in Bildern',
    'A Week in Pictures',
    'أسبوع بالصور',
    'Fotoğraflarla Bir Hafta',
    'Une semaine en images',
    'Una semana en fotos'
  ],
  'edTravel': [
    'Reise-Mosaik',
    'Travel Masonry',
    'فسيفساء السفر',
    'Seyahat Mozaiği',
    'Mosaïque de voyage',
    'Mosaico de viaje'
  ],
  'edMasonryOffset': [
    'Versetzte Spalten',
    'Offset Columns',
    'أعمدة متدرجة',
    'Kaydırılmış Sütunlar',
    'Colonnes décalées',
    'Columnas escalonadas'
  ],
  'edMasonryHero': [
    'Großer Moment',
    'Hero Moment',
    'لحظة مميزة',
    'Öne Çıkan An',
    'Moment phare',
    'Momento destacado'
  ],
  'edMemories': [
    'Erinnerungen auf Papier',
    'Torn Memories',
    'ذكريات على الورق',
    'Yırtık Anılar',
    'Souvenirs déchirés',
    'Recuerdos en papel'
  ],
  'edFocus': [
    'Details im Fokus',
    'Detail Focus',
    'التركيز على التفاصيل',
    'Ayrıntı Odağı',
    'Détails à la loupe',
    'Enfoque en detalles'
  ],
  'edJournal': [
    'Klares Journal',
    'Clean Journal',
    'يوميات بسيطة',
    'Sade Günlük',
    'Journal épuré',
    'Diario sencillo'
  ],
  'edSubtitle': [
    'Kleine Momente, große Erinnerungen',
    'Small moments, lasting memories',
    'لحظات صغيرة وذكريات باقية',
    'Küçük anlar, kalıcı anılar',
    'Petits instants, souvenirs durables',
    'Pequeños momentos, recuerdos duraderos'
  ],
  'edEvenings': [
    'Abende in',
    'evenings in',
    'أمسيات في',
    'akşamları',
    'soirées à',
    'tardes en'
  ],
  'edLocationExample': [
    'Santorini',
    'Santorini',
    'سانتوريني',
    'Santorini',
    'Santorin',
    'Santorini'
  ],
  'edMode_editorial': [
    'Editorial-Raster',
    'Editorial grid',
    'شبكة تحريرية',
    'Editoryal ızgara',
    'Grille éditoriale',
    'Cuadrícula editorial'
  ],
  'edMode_masonry': [
    'Asymmetrische Story',
    'Masonry story',
    'قصة غير متناظرة',
    'Asimetrik hikâye',
    'Story asymétrique',
    'Historia asimétrica'
  ],
  'edMode_torn': [
    'Gerissenes Papier',
    'Torn paper',
    'ورق ممزق',
    'Yırtık kâğıt',
    'Papier déchiré',
    'Papel rasgado'
  ],
  'edMode_detail': [
    'Detailausschnitte',
    'Detail callouts',
    'تفاصيل مكبرة',
    'Ayrıntı yakın planları',
    'Détails agrandis',
    'Detalles ampliados'
  ],
  'edChangeDesign': [
    'Design wechseln?',
    'Change design?',
    'تغيير التصميم؟',
    'Tasarım değiştirilsin mi?',
    'Changer de design ?',
    '¿Cambiar diseño?'
  ],
  'edChangeWarning': [
    'Dies ersetzt die Design-Ebenen. Originalfotos, Filter, normale Texte und Sticker bleiben erhalten. Rückgängig ist möglich.',
    'This replaces design layers. Original photos, filters, regular text and stickers are preserved. You can undo this.',
    'سيستبدل هذا طبقات التصميم. ستبقى الصور الأصلية والفلاتر والنصوص العادية والملصقات. يمكنك التراجع.',
    'Tasarım katmanları değiştirilir. Orijinal fotoğraflar, filtreler, normal metin ve çıkartmalar korunur. Geri alabilirsiniz.',
    'Les calques du design seront remplacés. Photos originales, filtres, textes classiques et stickers sont conservés. Vous pouvez annuler.',
    'Se reemplazan las capas del diseño. Se conservan fotos originales, filtros, textos normales y pegatinas. Puedes deshacerlo.'
  ],
  'edSpacingHint': [
    'Seitenabstände ordnen die Layout-Fotos neu an. Freie Ebenen bleiben an ihrem Platz.',
    'Page spacing reflows layout photos. Free layers keep their positions.',
    'تعيد مسافات الصفحة ترتيب صور التخطيط. تبقى الطبقات الحرة في أماكنها.',
    'Sayfa aralığı düzen fotoğraflarını yeniden yerleştirir. Serbest katmanlar yerinde kalır.',
    'Les espacements réorganisent les photos de mise en page. Les calques libres restent en place.',
    'El espaciado reorganiza las fotos del diseño. Las capas libres mantienen su posición.'
  ],
  'edAddTextHint': [
    'Titel und Beschriftungen lassen sich unter Ebenen bearbeiten oder hinzufügen.',
    'Edit or add titles and captions under Layers.',
    'يمكن تعديل العناوين والتعليقات أو إضافتها من الطبقات.',
    'Başlıkları ve açıklamaları Katmanlar bölümünden düzenleyin veya ekleyin.',
    'Modifiez ou ajoutez titres et légendes dans Calques.',
    'Edita o añade títulos y textos en Capas.'
  ],
  'edGestureHint': [
    'Ziehen: Ebene bewegen. Zwei Finger: Foto zoomen. Griffe: Größe und Drehung. Doppeltippen: bearbeiten.',
    'Drag to move a layer. Pinch to zoom photos. Handles resize and rotate. Double-tap to edit.',
    'اسحب لتحريك الطبقة. استخدم إصبعين لتكبير الصور. المقابض للحجم والتدوير. انقر مرتين للتعديل.',
    'Katmanı sürükleyin. Fotoğrafı iki parmakla yakınlaştırın. Tutamaçlarla boyutlandırıp döndürün. Düzenlemek için çift dokunun.',
    'Glissez pour déplacer. Pincez pour zoomer. Poignées pour taille et rotation. Double-touchez pour modifier.',
    'Arrastra para mover. Pellizca para ampliar. Usa controles para tamaño y giro. Toca dos veces para editar.'
  ],
  'edGapX': [
    'Spaltenabstand',
    'Column gap',
    'تباعد الأعمدة',
    'Sütun aralığı',
    'Écart des colonnes',
    'Espacio entre columnas'
  ],
  'edGapY': [
    'Zeilenabstand',
    'Row gap',
    'تباعد الصفوف',
    'Satır aralığı',
    'Écart des lignes',
    'Espacio entre filas'
  ],
  'edTitleArea': [
    'Titelbereich',
    'Title area',
    'منطقة العنوان',
    'Başlık alanı',
    'Zone de titre',
    'Área del título'
  ],
  'edColumns': [
    'Spalten',
    'Columns',
    'الأعمدة',
    'Sütunlar',
    'Colonnes',
    'Columnas'
  ],
  'edNumbering': [
    'Nummerierung',
    'Numbering',
    'الترقيم',
    'Numaralandırma',
    'Numérotation',
    'Numeración'
  ],
  'edNumber_parentheses': [
    '(1), (2), (3)',
    '(1), (2), (3)',
    '(1)، (2)، (3)',
    '(1), (2), (3)',
    '(1), (2), (3)',
    '(1), (2), (3)'
  ],
  'edNumber_plain': [
    '1, 2, 3',
    '1, 2, 3',
    '1، 2، 3',
    '1, 2, 3',
    '1, 2, 3',
    '1, 2, 3'
  ],
  'edNumber_padded': [
    '01, 02, 03',
    '01, 02, 03',
    '01، 02، 03',
    '01, 02, 03',
    '01, 02, 03',
    '01, 02, 03'
  ],
  'edNumber_custom': [
    'Eigene Beschriftung',
    'Custom captions',
    'تعليقات مخصصة',
    'Özel açıklamalar',
    'Légendes personnalisées',
    'Textos personalizados'
  ],
  'edNumber_hidden': [
    'Ausgeblendet',
    'Hidden',
    'مخفي',
    'Gizli',
    'Masquée',
    'Oculta'
  ],
  'edType_photo': ['Foto', 'Photo', 'صورة', 'Fotoğraf', 'Photo', 'Foto'],
  'edType_cell': [
    'Layout-Foto',
    'Layout photo',
    'صورة التخطيط',
    'Düzen fotoğrafı',
    'Photo de mise en page',
    'Foto del diseño'
  ],
  'edType_text': ['Text', 'Text', 'نص', 'Metin', 'Texte', 'Texto'],
  'edType_caption': [
    'Beschriftung',
    'Caption',
    'تعليق',
    'Açıklama',
    'Légende',
    'Texto de foto'
  ],
  'edType_background': [
    'Hintergrundebene',
    'Background layer',
    'طبقة خلفية',
    'Arka plan katmanı',
    'Calque de fond',
    'Capa de fondo'
  ],
  'edType_torn': [
    'Papierstreifen',
    'Paper strip',
    'شريط ورقي',
    'Kâğıt şeridi',
    'Bande de papier',
    'Tira de papel'
  ],
  'edType_callout': [
    'Detailausschnitt',
    'Detail callout',
    'تفصيل مكبر',
    'Ayrıntı yakın planı',
    'Détail agrandi',
    'Detalle ampliado'
  ],
  'edType_connector': [
    'Verbindungslinie',
    'Connector line',
    'خط توصيل',
    'Bağlantı çizgisi',
    'Ligne de liaison',
    'Línea conectora'
  ],
  'edType_location': [
    'Ortslabel',
    'Location label',
    'اسم المكان',
    'Konum etiketi',
    'Étiquette de lieu',
    'Etiqueta de lugar'
  ],
  'edForward': [
    'Nach vorne',
    'Bring forward',
    'إلى الأمام',
    'Öne getir',
    'Avancer',
    'Traer adelante'
  ],
  'edBackward': [
    'Nach hinten',
    'Send backward',
    'إلى الخلف',
    'Arkaya gönder',
    'Reculer',
    'Enviar atrás'
  ],
  'edLock': ['Sperren', 'Lock', 'قفل', 'Kilitle', 'Verrouiller', 'Bloquear'],
  'edUnlock': [
    'Entsperren',
    'Unlock',
    'فتح القفل',
    'Kilidi aç',
    'Déverrouiller',
    'Desbloquear'
  ],
  'edHide': ['Ausblenden', 'Hide', 'إخفاء', 'Gizle', 'Masquer', 'Ocultar'],
  'edShow': ['Einblenden', 'Show', 'إظهار', 'Göster', 'Afficher', 'Mostrar'],
  'edResize': [
    'Größe ändern',
    'Resize',
    'تغيير الحجم',
    'Boyutlandır',
    'Redimensionner',
    'Cambiar tamaño'
  ],
  'edPositionX': [
    'Position X',
    'Position X',
    'الموضع الأفقي',
    'X konumu',
    'Position X',
    'Posición X'
  ],
  'edPositionY': [
    'Position Y',
    'Position Y',
    'الموضع الرأسي',
    'Y konumu',
    'Position Y',
    'Posición Y'
  ],
  'edWidth': ['Breite', 'Width', 'العرض', 'Genişlik', 'Largeur', 'Ancho'],
  'edHeight': ['Höhe', 'Height', 'الارتفاع', 'Yükseklik', 'Hauteur', 'Alto'],
  'edOpacity': [
    'Deckkraft',
    'Opacity',
    'العتامة',
    'Opaklık',
    'Opacité',
    'Opacidad'
  ],
  'edSource': [
    'Quellfoto',
    'Source photo',
    'الصورة المصدر',
    'Kaynak fotoğraf',
    'Photo source',
    'Foto de origen'
  ],
  'edEditCrop': [
    'Zuschnitt bearbeiten',
    'Edit crop',
    'تعديل الاقتصاص',
    'Kırpmayı düzenle',
    'Modifier le cadrage',
    'Editar recorte'
  ],
  'edCropDone': [
    'Zuschnitt fertig',
    'Done cropping',
    'إنهاء الاقتصاص',
    'Kırpma tamam',
    'Terminer le cadrage',
    'Terminar recorte'
  ],
  'edFont': ['Schrift', 'Font', 'الخط', 'Yazı tipi', 'Police', 'Fuente'],
  'edFont_sans-serif': [
    'Sans Serif',
    'Sans serif',
    'بلا زوائد',
    'Sans serif',
    'Sans sérif',
    'Sin remates'
  ],
  'edFont_serif': ['Serif', 'Serif', 'بزوائد', 'Serif', 'Sérif', 'Con remates'],
  'edFont_monospace': [
    'Monospace',
    'Monospace',
    'ثابت العرض',
    'Eş aralıklı',
    'Monospace',
    'Monoespaciada'
  ],
  'edPadding': [
    'Innenabstand',
    'Padding',
    'المسافة الداخلية',
    'İç boşluk',
    'Marge intérieure',
    'Relleno'
  ],
  'edLabelRadius': [
    'Label-Rundung',
    'Label corner radius',
    'استدارة زوايا التسمية',
    'Etiket köşe yarıçapı',
    'Arrondi de l’étiquette',
    'Radio de etiqueta'
  ],
  'edLocationIcon': [
    'Ortssymbol anzeigen',
    'Show location icon',
    'إظهار رمز الموقع',
    'Konum simgesini göster',
    'Afficher l’icône de lieu',
    'Mostrar icono de ubicación'
  ],
  'edTearStyle': [
    'Papierkante',
    'Tear style',
    'نمط التمزق',
    'Yırtık stili',
    'Style de déchirure',
    'Estilo de rasgado'
  ],
  'edTear_soft': ['Weich', 'Soft', 'ناعم', 'Yumuşak', 'Doux', 'Suave'],
  'edTear_fibrous': [
    'Faserig',
    'Fibrous',
    'ليفي',
    'Lifli',
    'Fibreux',
    'Fibroso'
  ],
  'edTear_deckled': [
    'Büttenrand',
    'Deckled',
    'حافة خشنة',
    'Pürüzlü kenar',
    'Bord frangé',
    'Borde irregular'
  ],
  'edTear_weathered': [
    'Verwittert',
    'Weathered',
    'متآكل',
    'Eskimiş',
    'Patiné',
    'Desgastado'
  ],
  'edTearEdges': [
    'Gerissene Kanten',
    'Torn edges',
    'الحواف الممزقة',
    'Yırtık kenarlar',
    'Bords déchirés',
    'Bordes rasgados'
  ],
  'edEdges_top': ['Oben', 'Top', 'أعلى', 'Üst', 'Haut', 'Superior'],
  'edEdges_bottom': ['Unten', 'Bottom', 'أسفل', 'Alt', 'Bas', 'Inferior'],
  'edEdges_horizontal': [
    'Oben und unten',
    'Top and bottom',
    'أعلى وأسفل',
    'Üst ve alt',
    'Haut et bas',
    'Superior e inferior'
  ],
  'edEdges_vertical': [
    'Links und rechts',
    'Left and right',
    'يمين ويسار',
    'Sol ve sağ',
    'Gauche et droite',
    'Izquierdo y derecho'
  ],
  'edEdges_all': [
    'Alle Kanten',
    'All edges',
    'كل الحواف',
    'Tüm kenarlar',
    'Tous les bords',
    'Todos los bordes'
  ],
  'edTearIntensity': [
    'Rissstärke',
    'Tear intensity',
    'شدة التمزق',
    'Yırtık yoğunluğu',
    'Intensité',
    'Intensidad'
  ],
  'edRoughness': [
    'Rauheit',
    'Roughness',
    'الخشونة',
    'Pürüzlülük',
    'Rugosité',
    'Rugosidad'
  ],
  'edPaperShadow': [
    'Papierschatten',
    'Paper shadow',
    'ظل الورق',
    'Kâğıt gölgesi',
    'Ombre du papier',
    'Sombra del papel'
  ],
  'edShape': ['Form', 'Shape', 'الشكل', 'Şekil', 'Forme', 'Forma'],
  'edShape_rectangle': [
    'Rechteck',
    'Rectangle',
    'مستطيل',
    'Dikdörtgen',
    'Rectangle',
    'Rectángulo'
  ],
  'edShape_square': ['Quadrat', 'Square', 'مربع', 'Kare', 'Carré', 'Cuadrado'],
  'edShape_circle': ['Kreis', 'Circle', 'دائرة', 'Daire', 'Cercle', 'Círculo'],
  'edShape_rounded': [
    'Abgerundet',
    'Rounded rectangle',
    'مستطيل مستدير',
    'Yuvarlatılmış dikdörtgen',
    'Rectangle arrondi',
    'Rectángulo redondeado'
  ],
  'edSourceCrop': [
    'Quellausschnitt wählen',
    'Choose source crop',
    'اختيار منطقة المصدر',
    'Kaynak kırpmayı seç',
    'Choisir la zone source',
    'Elegir recorte de origen'
  ],
  'edCropHint': [
    'Rahmen ziehen, mit zwei Fingern skalieren oder Breite und Höhe einstellen.',
    'Drag the frame, pinch to scale, or adjust width and height.',
    'اسحب الإطار أو استخدم إصبعين لتغيير حجمه أو اضبط العرض والارتفاع.',
    'Çerçeveyi sürükleyin, iki parmakla ölçekleyin veya genişlik ve yüksekliği ayarlayın.',
    'Glissez le cadre, pincez pour redimensionner ou réglez largeur et hauteur.',
    'Arrastra el marco, pellizca para escalar o ajusta ancho y alto.'
  ],
  'edConnector': [
    'Verbindungslinie anzeigen',
    'Show connector',
    'إظهار خط التوصيل',
    'Bağlantıyı göster',
    'Afficher la liaison',
    'Mostrar conector'
  ],
  'edBorderWidth': [
    'Rahmenbreite',
    'Border width',
    'عرض الإطار',
    'Kenarlık genişliği',
    'Épaisseur du cadre',
    'Ancho del borde'
  ],
  'edBorderColor': [
    'Rahmenfarbe',
    'Border color',
    'لون الإطار',
    'Kenarlık rengi',
    'Couleur du cadre',
    'Color del borde'
  ],
  'edLineColor': [
    'Linienfarbe',
    'Line color',
    'لون الخط',
    'Çizgi rengi',
    'Couleur de ligne',
    'Color de línea'
  ],
  'edLineWidth': [
    'Linienbreite',
    'Line width',
    'عرض الخط',
    'Çizgi genişliği',
    'Épaisseur de ligne',
    'Ancho de línea'
  ],
  'edEndpointX': [
    'Linienende X',
    'Endpoint X',
    'نهاية الخط أفقيًا',
    'Bitiş noktası X',
    'Extrémité X',
    'Extremo X'
  ],
  'edEndpointY': [
    'Linienende Y',
    'Endpoint Y',
    'نهاية الخط رأسيًا',
    'Bitiş noktası Y',
    'Extrémité Y',
    'Extremo Y'
  ],
  'edCream': ['Creme', 'Cream', 'كريمي', 'Krem', 'Crème', 'Crema'],
  'edTransparent': [
    'Transparent',
    'Transparent',
    'شفاف',
    'Şeffaf',
    'Transparent',
    'Transparente'
  ],
  'edTranslucent': [
    'Durchscheinend',
    'Translucent',
    'شبه شفاف',
    'Yarı saydam',
    'Translucide',
    'Translúcido'
  ],
  'edCustomColor': [
    'Eigene Farbe',
    'Custom color',
    'لون مخصص',
    'Özel renk',
    'Couleur personnalisée',
    'Color personalizado'
  ],
  'edHexColor': [
    'Hex: AARRGGBB',
    'Hex: AARRGGBB',
    'ست عشري: AARRGGBB',
    'Hex: AARRGGBB',
    'Hex : AARRGGBB',
    'Hex: AARRGGBB'
  ],
  'edInvalidColor': [
    '8 Hex-Zeichen eingeben',
    'Enter 8 hex characters',
    'أدخل 8 رموز ست عشرية',
    '8 onaltılık karakter girin',
    'Saisissez 8 caractères hexadécimaux',
    'Introduce 8 caracteres hexadecimales'
  ],
};
