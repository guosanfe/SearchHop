import 'url_builder.dart';

class Site {
  Site({
    required this.name,
    required this.urlTemplate,
    this.appTemplate,
    this.androidPackage,
    this.appEncodeMode = EncodeMode.query,
    this.visible = true,
  });

  String name;
  String urlTemplate;
  String? appTemplate;
  String? androidPackage;
  EncodeMode appEncodeMode;
  bool visible;

  bool get hasApp => appTemplate != null && appTemplate!.trim().isNotEmpty;

  Map<String, dynamic> toJson() => {
        'name': name,
        'url_template': urlTemplate,
        if (hasApp) 'app_template': appTemplate,
        if (androidPackage != null && androidPackage!.isNotEmpty)
          'android_package': androidPackage,
        if (appEncodeMode != EncodeMode.query)
          'app_encode_mode': appEncodeMode.name,
        'visible': visible,
      };

  factory Site.fromJson(Map<String, dynamic> json) => Site(
        name: json['name'] as String,
        urlTemplate: json['url_template'] as String,
        appTemplate: json['app_template'] as String?,
        androidPackage: json['android_package'] as String?,
        appEncodeMode: EncodeMode.values
            .byName((json['app_encode_mode'] as String?) ?? 'query'),
        visible: json['visible'] as bool? ?? true,
      );
}