// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'تمبر';

  @override
  String get tabGuide => 'الدليل';

  @override
  String get tabArchive => 'المكتبة';

  @override
  String get tabBank => 'القوائم';

  @override
  String get tabScan => 'البحث';

  @override
  String get gateNoSignal => 'لا إشارة';

  @override
  String get gateBody =>
      'موسيقاك تبقى على جهازك.\nامنح إذن الوصول إلى الصوت ليتمكن الجهاز من فحص مكتبتك.';

  @override
  String get gateScanCta => 'افحص المحطات';

  @override
  String get gateDeniedNote =>
      'لا يمكن لتِمبر تصفح الموسيقى أو تشغيلها بدون هذا الإذن.';

  @override
  String get gateAccessOff => 'الوصول متوقف';

  @override
  String get gateAccessBody =>
      'يحتاج تمبر إلى إذن قراءة الملفات الصوتية. فعّله من إعدادات النظام ثم عُد.';

  @override
  String get gateOpenSettings => 'فتح الإعدادات';

  @override
  String get tipArchive => 'الأرشيف';

  @override
  String get tipScanner => 'الماسح';

  @override
  String get tipSettings => 'الإعدادات';

  @override
  String get tuned => 'مضبوط';

  @override
  String get stationArchive => 'الأرشيف';

  @override
  String get stationFlow => 'التدفق';

  @override
  String get stationFavorites => 'المفضلة';

  @override
  String get memoryBankPlaylists => 'بنك الذاكرة · القوائم';

  @override
  String get programGuide => 'دليل البرامج';

  @override
  String get noTransmissions =>
      'لا توجد محطات.\nأضف موسيقى إلى جهازك واسحب للفحص.';

  @override
  String get signalLost => 'انقطعت الإشارة';

  @override
  String get couldNotReadLibrary => 'تعذرت قراءة مكتبتك.';

  @override
  String get retryScan => 'إعادة الفحص';

  @override
  String get now => 'الآن';

  @override
  String get flow => 'تدفق';

  @override
  String get flowQueue => 'قائمة التدفق';

  @override
  String get flowMix => 'مزيج جديد من مكتبتك';

  @override
  String get onAir => 'على الهواء';

  @override
  String get noFavoritesSnack => 'لا مفضلات بعد — اضغط القلب على أي مقطع';

  @override
  String tracks(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n مقطعًا',
      few: '$n مقاطع',
      two: 'مقطعان',
      one: 'مقطع واحد',
    );
    return '$_temp0';
  }

  @override
  String get queueArchiveTitle => 'الأرشيف';

  @override
  String get queueFavoritesTitle => 'المفضلة';

  @override
  String flowQueueTitle(String title) {
    return 'تدفق · $title';
  }

  @override
  String get libraryTitle => 'المكتبة';

  @override
  String get tipRefresh => 'تحديث المكتبة';

  @override
  String get tabSongs => 'الأغاني';

  @override
  String get tabAlbums => 'الألبومات';

  @override
  String get tabArtists => 'الفنانون';

  @override
  String get tabGenres => 'الأنواع';

  @override
  String get tabFolders => 'المجلدات';

  @override
  String get couldNotLoad => 'تعذر تحميل موسيقاك';

  @override
  String get loadUnknownError => 'خطأ غير معروف';

  @override
  String get tryAgain => 'حاول مجددًا';

  @override
  String get emptyLibraryTitle => 'ستظهر موسيقاك هنا';

  @override
  String get emptyLibraryBody =>
      'يقرأ تمبر مكتبة الصوت في جهازك. عند العثور على موسيقى ستظهر فورًا.';

  @override
  String get scanLibrary => 'افحص المكتبة';

  @override
  String get rescanDevice => 'إعادة فحص موسيقى الجهاز';

  @override
  String songsFound(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'تم العثور على $n أغنية',
      few: 'تم العثور على $n أغانٍ',
      two: 'تم العثور على أغنيتين',
      one: 'تم العثور على أغنية واحدة',
      zero: 'لا موسيقى بعد',
    );
    return '$_temp0';
  }

  @override
  String get play => 'تشغيل';

  @override
  String get shuffle => 'عشوائي';

  @override
  String get noSongsHere => 'لا أغاني هنا بعد';

  @override
  String get songsWillShow => 'الأغاني التي تضيفها ستظهر في هذه القائمة.';

  @override
  String get playlistsTitle => 'القوائم';

  @override
  String get tipNewPlaylist => 'قائمة جديدة';

  @override
  String get emptyPlaylistsTitle => 'لا قوائم بعد';

  @override
  String get emptyPlaylistsBody => 'أنشئ قائمة لجلسة الاستماع القادمة.';

  @override
  String get favorites => 'المفضلة';

  @override
  String get tipRename => 'إعادة تسمية';

  @override
  String deletePlaylistTitle(String name) {
    return 'حذف \"$name\"؟';
  }

  @override
  String get deletePlaylistBody =>
      'تبقى الأغاني في مكتبتك. هذا يحذف القائمة فقط.';

  @override
  String get newPlaylistTitle => 'قائمة جديدة';

  @override
  String get renamePlaylistTitle => 'إعادة تسمية القائمة';

  @override
  String get playlistNameHint => 'اسم القائمة';

  @override
  String get favoriteSomeSnack => 'أضف أغاني إلى المفضلة لملء هذه القائمة.';

  @override
  String get searchHint => 'ابحث عن أغاني وفنانين وألبومات…';

  @override
  String get tipClear => 'مسح';

  @override
  String get nothingToSearchTitle => 'لا شيء للبحث عنه بعد';

  @override
  String get nothingToSearchBody => 'مكتبتك فارغة. افحص موسيقاك أولًا.';

  @override
  String get browseLibrary => 'تصفح مكتبتك';

  @override
  String get nothingFoundTitle => 'لا نتائج';

  @override
  String get nothingFoundBody => 'جرّب أغنية أو فنانًا أو ألبومًا آخر.';

  @override
  String get secArtists => 'الفنانون';

  @override
  String get secAlbums => 'الألبومات';

  @override
  String get secGenres => 'الأنواع';

  @override
  String get secSongs => 'الأغاني';

  @override
  String get queueTitle => 'القائمة';

  @override
  String get tipClearQueue => 'إفراغ القائمة';

  @override
  String get clearQueueTitle => 'إفراغ القائمة؟';

  @override
  String get clearQueueBody => 'سيؤدي هذا إلى إيقاف التشغيل وإفراغ القائمة.';

  @override
  String get queueEmptyTitle => 'القائمة فارغة';

  @override
  String get queueEmptyBody => 'شغّل أغنية لبناء قائمة.';

  @override
  String get nowPlaying => 'يُشغَّل الآن';

  @override
  String get upNext => 'التالي';

  @override
  String get tipAddFav => 'إضافة إلى المفضلة';

  @override
  String get tipRemoveFav => 'إزالة من المفضلة';

  @override
  String get tipMore => 'خيارات أخرى';

  @override
  String get playNext => 'تشغيل التالي';

  @override
  String get addToQueue => 'إضافة إلى القائمة';

  @override
  String get addToPlaylist => 'إضافة إلى قائمة…';

  @override
  String get addToPlaylistTitle => 'إضافة إلى قائمة';

  @override
  String addCountToPlaylist(int n) {
    return 'إضافة $n من الأغاني إلى قائمة';
  }

  @override
  String get goToAlbum => 'الذهاب إلى الألبوم';

  @override
  String get goToArtist => 'الذهاب إلى الفنان';

  @override
  String get shareAudioFile => 'مشاركة الملف الصوتي';

  @override
  String get deleteFromDevice => 'حذف من الجهاز';

  @override
  String get confirmDeleteTitle => 'حذف من الجهاز؟';

  @override
  String deleteOneTitle(String title) {
    return 'حذف \"$title\" من هذا الجهاز؟';
  }

  @override
  String deleteManyTitle(int n) {
    return 'حذف $n من الأغاني من هذا الجهاز؟';
  }

  @override
  String get deleteBody => 'سيتم حذف الملفات الصوتية نهائيًا.';

  @override
  String get tipClearSelection => 'مسح التحديد';

  @override
  String selAllTotal(int n) {
    return 'الكل $n';
  }

  @override
  String selCountAll(int n) {
    return '$n · الكل';
  }

  @override
  String get tipShare => 'مشاركة';

  @override
  String get tipAddToPlaylist => 'إضافة إلى قائمة';

  @override
  String get tipDelete => 'حذف من الجهاز';

  @override
  String get audioNotAvailable => 'الملف الصوتي غير متوفر للمشاركة.';

  @override
  String get nothingToShare => 'لا شيء للمشاركة.';

  @override
  String get couldNotDeleteSong => 'تعذر حذف هذه الأغنية.';

  @override
  String deletedAll(int n) {
    return 'تم الحذف ($n).';
  }

  @override
  String deletedPartial(int done, int total) {
    return 'تم حذف $done من $total.';
  }

  @override
  String get deleteNotAllowed => 'لم يُسمح بالحذف.';

  @override
  String get cannotDeleteHere => 'لا يمكن حذف هذه الأغنية من هنا.';

  @override
  String shareOneText(String title, String artist) {
    return '$title — $artist';
  }

  @override
  String shareManyText(int n) {
    return '$n من الأغاني من تمبر';
  }

  @override
  String get settingsTitle => 'الإعدادات';

  @override
  String get appearance => 'المظهر';

  @override
  String get languageSection => 'اللغة';

  @override
  String get langSystem => 'لغة النظام';

  @override
  String get langEnglish => 'الإنجليزية';

  @override
  String get langArabic => 'العربية';

  @override
  String get followSystem => 'اتباع النظام';

  @override
  String get light => 'فاتح';

  @override
  String get dark => 'داكن';

  @override
  String get listeningMemory => 'ذاكرة الاستماع';

  @override
  String get clearHistory => 'مسح سجل الاستماع';

  @override
  String get clearHistoryBody =>
      'يزيل عدد مرات التشغيل ومواضع الاستئناف والمتابعة.';

  @override
  String get clearHistoryTitle => 'مسح سجل الاستماع؟';

  @override
  String get clearHistoryContent => 'لا يمكن التراجع. تبقى المفضلة والقوائم.';

  @override
  String get librarySection => 'المكتبة';

  @override
  String get updatesSection => 'التحديثات';

  @override
  String get notificationsSection => 'الإشعارات';

  @override
  String get aboutSection => 'حول';

  @override
  String get musicStaysTitle => 'موسيقاك تبقى على جهازك';

  @override
  String get musicStaysBody =>
      'يقرأ تمبر الملفات الصوتية لتشغيلها فقط. لا حساب ولا تتبع. التحديثات تفحص غيت هب فقط عندما تطلب.';

  @override
  String get aboutTimbre => 'تمبر';

  @override
  String versionLine(String v) {
    return 'الإصدار $v · مشغّل موسيقى هادئ';
  }

  @override
  String get timbreVersion => 'إصدار تمبر';

  @override
  String installedVersion(String v) {
    return 'المثبت: $v';
  }

  @override
  String get checkUpdates => 'التحقق من التحديثات';

  @override
  String get checkUpdatesSub => 'يقارن مع أحدث إصدار على غيت هب.';

  @override
  String get checking => 'جارٍ التحقق…';

  @override
  String get upToDate => 'لديك أحدث إصدار.';

  @override
  String updateAvailable(String v) {
    return 'يتوفر التحديث $v';
  }

  @override
  String installedTo(String cur, String v) {
    return 'المثبت $cur ← $v.';
  }

  @override
  String get downloadInstall => 'تنزيل وتثبيت';

  @override
  String get startingDownload => 'بدء التنزيل…';

  @override
  String get downloadDoneInstaller =>
      'اكتمل التنزيل — فتح المثبّت… اضغط تثبيت للإنهاء.';

  @override
  String get installedRestart =>
      'تم التثبيت. أعد تشغيل التطبيق إذا كان مفتوحًا.';

  @override
  String get downloadCanceled => 'أُلغي التنزيل.';

  @override
  String get allowInstalls => 'السماح بالتثبيت';

  @override
  String get installBlocked =>
      'منع أندرويد التثبيت. اسمح بـ«تثبيت التطبيقات غير المعروفة» لتمبر ثم أعد المحاولة.';

  @override
  String get notifOnTitle => 'عناصر التحكم الخلفية مفعّلة';

  @override
  String get notifOnBody => 'تظهر عناصر التحكم على شاشة القفل وفي الإشعارات.';

  @override
  String get notifOffTitle => 'عناصر التحكم الخلفية متوقفة';

  @override
  String get notifOffBody =>
      'الموسيقى تعمل. فعّل الإشعارات لعناصر التحكم على القفل.';

  @override
  String get notifOffBodyDenied =>
      'الموسيقى تعمل. فعّل الإشعارات من إعدادات النظام لعناصر القفل.';

  @override
  String get errNoConnection => 'لا اتصال. اتصل بالإنترنت وأعد المحاولة.';

  @override
  String get errTimeout => 'انتهت مهلة التحقق. تحقق من الاتصال وأعد المحاولة.';

  @override
  String get errNetwork => 'خطأ في الشبكة. تحقق من الاتصال وأعد المحاولة.';

  @override
  String get errGeneric => 'تعذر التحقق من التحديثات. حاول مجددًا.';

  @override
  String get errNoReleases => 'لا إصدارات منشورة بعد.';

  @override
  String get errRateLimit => 'تم تجاوز حد غيت هب. حاول لاحقًا.';

  @override
  String errHttp(int code) {
    return 'فشل التحقق (HTTP $code). حاول مجددًا.';
  }

  @override
  String get errUnexpected => 'رد غير متوقع. حاول مجددًا.';

  @override
  String get errNoApk => 'أحدث إصدار لا يحتوي ملف APK.';

  @override
  String evtDownloading(String p) {
    return 'جارٍ تنزيل التحديث… $p٪';
  }

  @override
  String get evtDownloadingPlain => 'جارٍ تنزيل التحديث…';

  @override
  String get evtInstalling => 'اكتمل التنزيل — فتح المثبّت…';

  @override
  String get evtRunning => 'هناك تحديث يعمل بالفعل.';

  @override
  String get evtPermDenied => 'تم رفض إذن التثبيت.';

  @override
  String get evtDownloadError => 'فشل التنزيل. تحقق من الاتصال وأعد المحاولة.';

  @override
  String get evtChecksumError => 'فشل التحقق من الملف. أعد المحاولة.';

  @override
  String get evtCanceled => 'أُلغي التنزيل.';

  @override
  String get evtInstallError => 'أبلغ التثبيت عن خطأ.';

  @override
  String get evtInstalled => 'تم التثبيت.';

  @override
  String get evtInternal => 'حدث خطأ. حاول مجددًا.';

  @override
  String evtInternalDetail(String d) {
    return 'حدث خطأ: $d';
  }

  @override
  String get tipMinimize => 'تصغير';

  @override
  String get tipQueue => 'القائمة';

  @override
  String get tipSleep => 'مؤقت النوم';

  @override
  String get tipSpeed => 'سرعة التشغيل';

  @override
  String get tipShuffle => 'عشوائي';

  @override
  String get tipPrevious => 'السابق';

  @override
  String get tipPlay => 'تشغيل';

  @override
  String get tipPause => 'إيقاف مؤقت';

  @override
  String get tipNext => 'التالي';

  @override
  String get repeatOff => 'التكرار متوقف';

  @override
  String get repeatAll => 'تكرار الكل';

  @override
  String get repeatOne => 'تكرار واحد';

  @override
  String get sleepTitle => 'مؤقت النوم';

  @override
  String get sleepEndOfTrack => 'نهاية المقطع الحالي';

  @override
  String get sleepWillPauseEnd => 'سيتوقف في نهاية هذا المقطع';

  @override
  String sleepPausingIn(String r) {
    return 'التوقف بعد $r';
  }

  @override
  String minutesCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n دقيقة',
      few: '$n دقائق',
      two: 'دقيقتان',
      one: 'دقيقة واحدة',
    );
    return '$_temp0';
  }

  @override
  String remainingShort(int m, String s) {
    return '$m د $s ث';
  }

  @override
  String secondsShort(int s) {
    return '$s ث';
  }

  @override
  String get remainingWord => 'متبقٍ';

  @override
  String get speedTitle => 'سرعة التشغيل';

  @override
  String get unknownArtist => 'فنان غير معروف';

  @override
  String get unknownAlbum => 'ألبوم غير معروف';

  @override
  String get flowPlain => 'مبني من مكتبتك';

  @override
  String get flowSocial => 'فنانون مشابهون + مفضلاتك';

  @override
  String get flowRecent => 'فنانون مشابهون + أحدث المفضلات';

  @override
  String get flowArtist => 'مبني على هذا الفنان واستماعك';

  @override
  String songsCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n أغنية',
      many: '$n أغنية',
      few: '$n أغانٍ',
      two: 'أغنيتان',
      one: 'أغنية واحدة',
      zero: 'لا أغاني',
    );
    return '$_temp0';
  }

  @override
  String totalDuration(int h, int m) {
    String _temp0 = intl.Intl.pluralLogic(
      h,
      locale: localeName,
      other: '$h س $m دقيقة',
      zero: '$m دقيقة',
    );
    return '$_temp0';
  }

  @override
  String get cancel => 'إلغاء';

  @override
  String get delete => 'حذف';

  @override
  String get clear => 'مسح';

  @override
  String get save => 'حفظ';

  @override
  String get create => 'إنشاء';
}
