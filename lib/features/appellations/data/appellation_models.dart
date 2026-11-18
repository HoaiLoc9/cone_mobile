import '../../../core/config/api_config.dart';

class AppellationList {
  const AppellationList({required this.items});

  final List<AppellationItem> items;

  factory AppellationList.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? {};
    final items = data['items'] as List<dynamic>? ?? [];
    return AppellationList(
      items: items
          .map((item) => AppellationItem.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

class AppellationDetail {
  const AppellationDetail({
    required this.appellation,
    required this.registration,
  });

  final AppellationItem appellation;
  final AppellationRegistration? registration;

  factory AppellationDetail.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? {};
    return AppellationDetail(
      appellation: AppellationItem.fromJson(
        data['appellation'] as Map<String, dynamic>? ?? {},
      ),
      registration: data['registration'] == null
          ? null
          : AppellationRegistration.fromJson(
              data['registration'] as Map<String, dynamic>,
            ),
    );
  }
}

class AppellationItem {
  const AppellationItem({
    required this.id,
    required this.name,
    required this.note,
    required this.avatarUrl,
    required this.timeStart,
    required this.timeStop,
    required this.resultPublishDate,
    required this.isOpen,
    required this.hasDynamicForm,
    required this.formSchema,
    required this.myRegistration,
  });

  final String id;
  final String name;
  final String note;
  final String avatarUrl;
  final DateTime? timeStart;
  final DateTime? timeStop;
  final String resultPublishDate;
  final bool isOpen;
  final bool hasDynamicForm;
  final AppellationFormSchema? formSchema;
  final AppellationRegistration? myRegistration;

  bool get isRegistered => myRegistration != null;

  factory AppellationItem.fromJson(Map<String, dynamic> json) {
    return AppellationItem(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      note: json['note']?.toString() ?? '',
      avatarUrl: ApiConfig.storageUrl(json['avatar_url']?.toString() ?? ''),
      timeStart: _parseDate(json['time_start']),
      timeStop: _parseDate(json['time_stop']),
      resultPublishDate: json['result_publish_date']?.toString() ?? '',
      isOpen: json['is_open'] == true,
      hasDynamicForm: json['has_dynamic_form'] == true,
      formSchema: json['form_schema'] == null
          ? null
          : AppellationFormSchema.fromJson(
              json['form_schema'] as Map<String, dynamic>,
            ),
      myRegistration: json['my_registration'] == null
          ? null
          : AppellationRegistration.fromJson(
              json['my_registration'] as Map<String, dynamic>,
            ),
    );
  }
}

class AppellationRegistration {
  const AppellationRegistration({
    required this.id,
    required this.appellationId,
    required this.appellationName,
    required this.status,
    required this.statusLabel,
    required this.workflowLabel,
    required this.canEdit,
    required this.createdAt,
    required this.updatedAt,
    required this.file,
    required this.proof,
    required this.formData,
    required this.formFiles,
  });

  final String id;
  final String appellationId;
  final String appellationName;
  final int status;
  final String statusLabel;
  final String workflowLabel;
  final bool canEdit;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final AppellationFile? file;
  final AppellationFile? proof;
  final Map<String, dynamic> formData;
  final Map<String, List<AppellationFile>> formFiles;

  factory AppellationRegistration.fromJson(Map<String, dynamic> json) {
    final filesJson = json['form_files'] as Map<String, dynamic>? ?? {};
    return AppellationRegistration(
      id: json['id']?.toString() ?? '',
      appellationId: json['appellation_id']?.toString() ?? '',
      appellationName: json['appellation_name']?.toString() ?? '',
      status: (json['status'] as num?)?.toInt() ?? 0,
      statusLabel: json['status_label']?.toString() ?? '',
      workflowLabel: json['workflow_label']?.toString() ?? '',
      canEdit: json['can_edit'] == true,
      createdAt: _parseDate(json['created_at']),
      updatedAt: _parseDate(json['updated_at']),
      file: json['file'] == null
          ? null
          : AppellationFile.fromJson(json['file'] as Map<String, dynamic>),
      proof: json['proof'] == null
          ? null
          : AppellationFile.fromJson(json['proof'] as Map<String, dynamic>),
      formData: json['form_data'] as Map<String, dynamic>? ?? {},
      formFiles: filesJson.map(
        (key, value) => MapEntry(
          key,
          (value as List<dynamic>? ?? [])
              .map(
                (item) =>
                    AppellationFile.fromJson(item as Map<String, dynamic>),
              )
              .toList(),
        ),
      ),
    );
  }
}

class AppellationFormSchema {
  const AppellationFormSchema({required this.version, required this.fields});

  final int version;
  final List<AppellationFormField> fields;

  factory AppellationFormSchema.fromJson(Map<String, dynamic> json) {
    final fields = json['fields'] as List<dynamic>? ?? [];
    return AppellationFormSchema(
      version: (json['version'] as num?)?.toInt() ?? 1,
      fields: fields
          .map(
            (item) =>
                AppellationFormField.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
    );
  }
}

class AppellationFormField {
  const AppellationFormField({
    required this.key,
    required this.label,
    required this.type,
    required this.required,
    required this.help,
    required this.options,
  });

  final String key;
  final String label;
  final String type;
  final bool required;
  final String help;
  final List<String> options;

  factory AppellationFormField.fromJson(Map<String, dynamic> json) {
    final options = json['options'] as List<dynamic>? ?? [];
    return AppellationFormField(
      key: json['key']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
      type: json['type']?.toString() ?? 'text',
      required: json['required'] == true,
      help: json['help']?.toString() ?? '',
      options: options.map((item) => item.toString()).toList(),
    );
  }
}

class AppellationFile {
  const AppellationFile({
    required this.name,
    required this.path,
    required this.url,
  });

  final String name;
  final String path;
  final String url;

  factory AppellationFile.fromJson(Map<String, dynamic> json) {
    return AppellationFile(
      name: json['name']?.toString() ?? '',
      path: json['path']?.toString() ?? '',
      url: ApiConfig.storageUrl(json['url']?.toString() ?? ''),
    );
  }
}

DateTime? _parseDate(Object? value) {
  final text = value?.toString();
  if (text == null || text.isEmpty) {
    return null;
  }
  return DateTime.tryParse(text)?.toLocal();
}
