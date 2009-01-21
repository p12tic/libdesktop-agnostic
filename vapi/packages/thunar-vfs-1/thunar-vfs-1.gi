<?xml version="1.0"?>
<api version="1.0">
	<namespace name="ThunarVfs">
		<function name="canonicalize_filename" symbol="thunar_vfs_canonicalize_filename">
			<return-type type="gchar*"/>
			<parameters>
				<parameter name="filename" type="gchar*"/>
			</parameters>
		</function>
		<function name="change_group" symbol="thunar_vfs_change_group">
			<return-type type="ThunarVfsJob*"/>
			<parameters>
				<parameter name="path" type="ThunarVfsPath*"/>
				<parameter name="gid" type="ThunarVfsGroupId"/>
				<parameter name="recursive" type="gboolean"/>
				<parameter name="error" type="GError**"/>
			</parameters>
		</function>
		<function name="change_mode" symbol="thunar_vfs_change_mode">
			<return-type type="ThunarVfsJob*"/>
			<parameters>
				<parameter name="path" type="ThunarVfsPath*"/>
				<parameter name="dir_mask" type="ThunarVfsFileMode"/>
				<parameter name="dir_mode" type="ThunarVfsFileMode"/>
				<parameter name="file_mask" type="ThunarVfsFileMode"/>
				<parameter name="file_mode" type="ThunarVfsFileMode"/>
				<parameter name="recursive" type="gboolean"/>
				<parameter name="error" type="GError**"/>
			</parameters>
		</function>
		<function name="change_owner" symbol="thunar_vfs_change_owner">
			<return-type type="ThunarVfsJob*"/>
			<parameters>
				<parameter name="path" type="ThunarVfsPath*"/>
				<parameter name="uid" type="ThunarVfsUserId"/>
				<parameter name="recursive" type="gboolean"/>
				<parameter name="error" type="GError**"/>
			</parameters>
		</function>
		<function name="check_version" symbol="thunar_vfs_check_version">
			<return-type type="gchar*"/>
			<parameters>
				<parameter name="required_major" type="guint"/>
				<parameter name="required_minor" type="guint"/>
				<parameter name="required_micro" type="guint"/>
			</parameters>
		</function>
		<function name="copy_file" symbol="thunar_vfs_copy_file">
			<return-type type="ThunarVfsJob*"/>
			<parameters>
				<parameter name="source_path" type="ThunarVfsPath*"/>
				<parameter name="target_path" type="ThunarVfsPath*"/>
				<parameter name="error" type="GError**"/>
			</parameters>
		</function>
		<function name="copy_files" symbol="thunar_vfs_copy_files">
			<return-type type="ThunarVfsJob*"/>
			<parameters>
				<parameter name="source_path_list" type="GList*"/>
				<parameter name="target_path_list" type="GList*"/>
				<parameter name="error" type="GError**"/>
			</parameters>
		</function>
		<function name="create_file" symbol="thunar_vfs_create_file">
			<return-type type="ThunarVfsJob*"/>
			<parameters>
				<parameter name="path" type="ThunarVfsPath*"/>
				<parameter name="error" type="GError**"/>
			</parameters>
		</function>
		<function name="create_files" symbol="thunar_vfs_create_files">
			<return-type type="ThunarVfsJob*"/>
			<parameters>
				<parameter name="path_list" type="GList*"/>
				<parameter name="error" type="GError**"/>
			</parameters>
		</function>
		<function name="deep_count" symbol="thunar_vfs_deep_count">
			<return-type type="ThunarVfsJob*"/>
			<parameters>
				<parameter name="path" type="ThunarVfsPath*"/>
				<parameter name="flags" type="ThunarVfsDeepCountFlags"/>
				<parameter name="error" type="GError**"/>
			</parameters>
		</function>
		<function name="expand_filename" symbol="thunar_vfs_expand_filename">
			<return-type type="gchar*"/>
			<parameters>
				<parameter name="filename" type="gchar*"/>
				<parameter name="error" type="GError**"/>
			</parameters>
		</function>
		<function name="humanize_size" symbol="thunar_vfs_humanize_size">
			<return-type type="gchar*"/>
			<parameters>
				<parameter name="size" type="ThunarVfsFileSize"/>
				<parameter name="buffer" type="gchar*"/>
				<parameter name="buflen" type="gsize"/>
			</parameters>
		</function>
		<function name="init" symbol="thunar_vfs_init">
			<return-type type="void"/>
		</function>
		<function name="link_file" symbol="thunar_vfs_link_file">
			<return-type type="ThunarVfsJob*"/>
			<parameters>
				<parameter name="source_path" type="ThunarVfsPath*"/>
				<parameter name="target_path" type="ThunarVfsPath*"/>
				<parameter name="error" type="GError**"/>
			</parameters>
		</function>
		<function name="link_files" symbol="thunar_vfs_link_files">
			<return-type type="ThunarVfsJob*"/>
			<parameters>
				<parameter name="source_path_list" type="GList*"/>
				<parameter name="target_path_list" type="GList*"/>
				<parameter name="error" type="GError**"/>
			</parameters>
		</function>
		<function name="listdir" symbol="thunar_vfs_listdir">
			<return-type type="ThunarVfsJob*"/>
			<parameters>
				<parameter name="path" type="ThunarVfsPath*"/>
				<parameter name="error" type="GError**"/>
			</parameters>
		</function>
		<function name="make_directories" symbol="thunar_vfs_make_directories">
			<return-type type="ThunarVfsJob*"/>
			<parameters>
				<parameter name="path_list" type="GList*"/>
				<parameter name="error" type="GError**"/>
			</parameters>
		</function>
		<function name="make_directory" symbol="thunar_vfs_make_directory">
			<return-type type="ThunarVfsJob*"/>
			<parameters>
				<parameter name="path" type="ThunarVfsPath*"/>
				<parameter name="error" type="GError**"/>
			</parameters>
		</function>
		<function name="move_file" symbol="thunar_vfs_move_file">
			<return-type type="ThunarVfsJob*"/>
			<parameters>
				<parameter name="source_path" type="ThunarVfsPath*"/>
				<parameter name="target_path" type="ThunarVfsPath*"/>
				<parameter name="error" type="GError**"/>
			</parameters>
		</function>
		<function name="move_files" symbol="thunar_vfs_move_files">
			<return-type type="ThunarVfsJob*"/>
			<parameters>
				<parameter name="source_path_list" type="GList*"/>
				<parameter name="target_path_list" type="GList*"/>
				<parameter name="error" type="GError**"/>
			</parameters>
		</function>
		<function name="shutdown" symbol="thunar_vfs_shutdown">
			<return-type type="void"/>
		</function>
		<function name="thumbnail_for_path" symbol="thunar_vfs_thumbnail_for_path">
			<return-type type="gchar*"/>
			<parameters>
				<parameter name="path" type="ThunarVfsPath*"/>
				<parameter name="size" type="ThunarVfsThumbSize"/>
			</parameters>
		</function>
		<function name="thumbnail_is_valid" symbol="thunar_vfs_thumbnail_is_valid">
			<return-type type="gboolean"/>
			<parameters>
				<parameter name="thumbnail" type="gchar*"/>
				<parameter name="uri" type="gchar*"/>
				<parameter name="mtime" type="ThunarVfsFileTime"/>
			</parameters>
		</function>
		<function name="unlink_file" symbol="thunar_vfs_unlink_file">
			<return-type type="ThunarVfsJob*"/>
			<parameters>
				<parameter name="path" type="ThunarVfsPath*"/>
				<parameter name="error" type="GError**"/>
			</parameters>
		</function>
		<function name="unlink_files" symbol="thunar_vfs_unlink_files">
			<return-type type="ThunarVfsJob*"/>
			<parameters>
				<parameter name="path_list" type="GList*"/>
				<parameter name="error" type="GError**"/>
			</parameters>
		</function>
		<callback name="ThunarVfsMonitorCallback">
			<return-type type="void"/>
			<parameters>
				<parameter name="monitor" type="ThunarVfsMonitor*"/>
				<parameter name="handle" type="ThunarVfsMonitorHandle*"/>
				<parameter name="event" type="ThunarVfsMonitorEvent"/>
				<parameter name="handle_path" type="ThunarVfsPath*"/>
				<parameter name="event_path" type="ThunarVfsPath*"/>
				<parameter name="user_data" type="gpointer"/>
			</parameters>
		</callback>
		<struct name="ThunarVfsFileDevice">
		</struct>
		<struct name="ThunarVfsFileSize">
		</struct>
		<struct name="ThunarVfsFileTime">
		</struct>
		<struct name="ThunarVfsGroupClass">
		</struct>
		<struct name="ThunarVfsGroupId">
		</struct>
		<struct name="ThunarVfsMimeActionClass">
		</struct>
		<struct name="ThunarVfsMimeApplicationClass">
		</struct>
		<struct name="ThunarVfsMimeDatabaseClass">
		</struct>
		<struct name="ThunarVfsMimeHandlerClass">
		</struct>
		<struct name="ThunarVfsMonitorClass">
		</struct>
		<struct name="ThunarVfsMonitorHandle">
		</struct>
		<struct name="ThunarVfsThumbFactoryClass">
		</struct>
		<struct name="ThunarVfsUserClass">
		</struct>
		<struct name="ThunarVfsUserId">
		</struct>
		<struct name="ThunarVfsUserManagerClass">
		</struct>
		<struct name="ThunarVfsVolumeClass">
		</struct>
		<struct name="ThunarVfsVolumeManagerClass">
		</struct>
		<boxed name="ThunarVfsInfo" type-name="ThunarVfsInfo" get-type="thunar_vfs_info_get_type">
			<method name="copy" symbol="thunar_vfs_info_copy">
				<return-type type="ThunarVfsInfo*"/>
				<parameters>
					<parameter name="info" type="ThunarVfsInfo*"/>
				</parameters>
			</method>
			<method name="execute" symbol="thunar_vfs_info_execute">
				<return-type type="gboolean"/>
				<parameters>
					<parameter name="info" type="ThunarVfsInfo*"/>
					<parameter name="screen" type="GdkScreen*"/>
					<parameter name="path_list" type="GList*"/>
					<parameter name="working_directory" type="gchar*"/>
					<parameter name="error" type="GError**"/>
				</parameters>
			</method>
			<method name="get_custom_icon" symbol="thunar_vfs_info_get_custom_icon">
				<return-type type="gchar*"/>
				<parameters>
					<parameter name="info" type="ThunarVfsInfo*"/>
				</parameters>
			</method>
			<method name="get_free_space" symbol="thunar_vfs_info_get_free_space">
				<return-type type="gboolean"/>
				<parameters>
					<parameter name="info" type="ThunarVfsInfo*"/>
					<parameter name="free_space_return" type="ThunarVfsFileSize*"/>
				</parameters>
			</method>
			<method name="get_metadata" symbol="thunar_vfs_info_get_metadata">
				<return-type type="gchar*"/>
				<parameters>
					<parameter name="info" type="ThunarVfsInfo*"/>
					<parameter name="metadata" type="ThunarVfsInfoMetadata"/>
					<parameter name="error" type="GError**"/>
				</parameters>
			</method>
			<method name="list_free" symbol="thunar_vfs_info_list_free">
				<return-type type="void"/>
				<parameters>
					<parameter name="info_list" type="GList*"/>
				</parameters>
			</method>
			<method name="matches" symbol="thunar_vfs_info_matches">
				<return-type type="gboolean"/>
				<parameters>
					<parameter name="a" type="ThunarVfsInfo*"/>
					<parameter name="b" type="ThunarVfsInfo*"/>
				</parameters>
			</method>
			<constructor name="new_for_path" symbol="thunar_vfs_info_new_for_path">
				<return-type type="ThunarVfsInfo*"/>
				<parameters>
					<parameter name="path" type="ThunarVfsPath*"/>
					<parameter name="error" type="GError**"/>
				</parameters>
			</constructor>
			<method name="read_link" symbol="thunar_vfs_info_read_link">
				<return-type type="gchar*"/>
				<parameters>
					<parameter name="info" type="ThunarVfsInfo*"/>
					<parameter name="error" type="GError**"/>
				</parameters>
			</method>
			<method name="ref" symbol="thunar_vfs_info_ref">
				<return-type type="ThunarVfsInfo*"/>
				<parameters>
					<parameter name="info" type="ThunarVfsInfo*"/>
				</parameters>
			</method>
			<method name="rename" symbol="thunar_vfs_info_rename">
				<return-type type="gboolean"/>
				<parameters>
					<parameter name="info" type="ThunarVfsInfo*"/>
					<parameter name="name" type="gchar*"/>
					<parameter name="error" type="GError**"/>
				</parameters>
			</method>
			<method name="set_custom_icon" symbol="thunar_vfs_info_set_custom_icon">
				<return-type type="gboolean"/>
				<parameters>
					<parameter name="info" type="ThunarVfsInfo*"/>
					<parameter name="custom_icon" type="gchar*"/>
					<parameter name="error" type="GError**"/>
				</parameters>
			</method>
			<method name="unref" symbol="thunar_vfs_info_unref">
				<return-type type="void"/>
				<parameters>
					<parameter name="info" type="ThunarVfsInfo*"/>
				</parameters>
			</method>
			<field name="type" type="ThunarVfsFileType"/>
			<field name="mode" type="ThunarVfsFileMode"/>
			<field name="flags" type="ThunarVfsFileFlags"/>
			<field name="uid" type="ThunarVfsUserId"/>
			<field name="gid" type="ThunarVfsGroupId"/>
			<field name="size" type="ThunarVfsFileSize"/>
			<field name="atime" type="ThunarVfsFileTime"/>
			<field name="mtime" type="ThunarVfsFileTime"/>
			<field name="ctime" type="ThunarVfsFileTime"/>
			<field name="device" type="ThunarVfsFileDevice"/>
			<field name="mime_info" type="ThunarVfsMimeInfo*"/>
			<field name="path" type="ThunarVfsPath*"/>
			<field name="custom_icon" type="gchar*"/>
			<field name="display_name" type="gchar*"/>
			<field name="ref_count" type="gint"/>
		</boxed>
		<boxed name="ThunarVfsMimeInfo" type-name="ThunarVfsMimeInfo" get-type="thunar_vfs_mime_info_get_type">
			<method name="equal" symbol="thunar_vfs_mime_info_equal">
				<return-type type="gboolean"/>
				<parameters>
					<parameter name="a" type="gconstpointer"/>
					<parameter name="b" type="gconstpointer"/>
				</parameters>
			</method>
			<method name="get_comment" symbol="thunar_vfs_mime_info_get_comment">
				<return-type type="gchar*"/>
				<parameters>
					<parameter name="info" type="ThunarVfsMimeInfo*"/>
				</parameters>
			</method>
			<method name="get_media" symbol="thunar_vfs_mime_info_get_media">
				<return-type type="gchar*"/>
				<parameters>
					<parameter name="info" type="ThunarVfsMimeInfo*"/>
				</parameters>
			</method>
			<method name="get_name" symbol="thunar_vfs_mime_info_get_name">
				<return-type type="gchar*"/>
				<parameters>
					<parameter name="info" type="ThunarVfsMimeInfo*"/>
				</parameters>
			</method>
			<method name="get_subtype" symbol="thunar_vfs_mime_info_get_subtype">
				<return-type type="gchar*"/>
				<parameters>
					<parameter name="info" type="ThunarVfsMimeInfo*"/>
				</parameters>
			</method>
			<method name="hash" symbol="thunar_vfs_mime_info_hash">
				<return-type type="guint"/>
				<parameters>
					<parameter name="info" type="gconstpointer"/>
				</parameters>
			</method>
			<method name="list_free" symbol="thunar_vfs_mime_info_list_free">
				<return-type type="void"/>
				<parameters>
					<parameter name="info_list" type="GList*"/>
				</parameters>
			</method>
			<method name="lookup_icon_name" symbol="thunar_vfs_mime_info_lookup_icon_name">
				<return-type type="gchar*"/>
				<parameters>
					<parameter name="info" type="ThunarVfsMimeInfo*"/>
					<parameter name="icon_theme" type="GtkIconTheme*"/>
				</parameters>
			</method>
			<constructor name="new" symbol="thunar_vfs_mime_info_new">
				<return-type type="ThunarVfsMimeInfo*"/>
				<parameters>
					<parameter name="name" type="gchar*"/>
					<parameter name="len" type="gssize"/>
				</parameters>
			</constructor>
			<method name="ref" symbol="thunar_vfs_mime_info_ref">
				<return-type type="ThunarVfsMimeInfo*"/>
				<parameters>
					<parameter name="info" type="ThunarVfsMimeInfo*"/>
				</parameters>
			</method>
			<method name="unref" symbol="thunar_vfs_mime_info_unref">
				<return-type type="void"/>
				<parameters>
					<parameter name="info" type="ThunarVfsMimeInfo*"/>
				</parameters>
			</method>
			<field name="ref_count" type="gint"/>
			<field name="comment" type="gchar*"/>
			<field name="icon_name" type="gchar*"/>
		</boxed>
		<boxed name="ThunarVfsPath" type-name="ThunarVfsPath" get-type="thunar_vfs_path_get_type">
			<method name="dup_string" symbol="thunar_vfs_path_dup_string">
				<return-type type="gchar*"/>
				<parameters>
					<parameter name="path" type="ThunarVfsPath*"/>
				</parameters>
			</method>
			<method name="dup_uri" symbol="thunar_vfs_path_dup_uri">
				<return-type type="gchar*"/>
				<parameters>
					<parameter name="path" type="ThunarVfsPath*"/>
				</parameters>
			</method>
			<method name="equal" symbol="thunar_vfs_path_equal">
				<return-type type="gboolean"/>
				<parameters>
					<parameter name="path_ptr_a" type="gconstpointer"/>
					<parameter name="path_ptr_b" type="gconstpointer"/>
				</parameters>
			</method>
			<method name="get_for_home" symbol="thunar_vfs_path_get_for_home">
				<return-type type="ThunarVfsPath*"/>
			</method>
			<method name="get_for_root" symbol="thunar_vfs_path_get_for_root">
				<return-type type="ThunarVfsPath*"/>
			</method>
			<method name="get_for_trash" symbol="thunar_vfs_path_get_for_trash">
				<return-type type="ThunarVfsPath*"/>
			</method>
			<method name="get_name" symbol="thunar_vfs_path_get_name">
				<return-type type="gchar*"/>
				<parameters>
					<parameter name="path" type="ThunarVfsPath*"/>
				</parameters>
			</method>
			<method name="get_parent" symbol="thunar_vfs_path_get_parent">
				<return-type type="ThunarVfsPath*"/>
				<parameters>
					<parameter name="path" type="ThunarVfsPath*"/>
				</parameters>
			</method>
			<method name="get_scheme" symbol="thunar_vfs_path_get_scheme">
				<return-type type="ThunarVfsPathScheme"/>
				<parameters>
					<parameter name="path" type="ThunarVfsPath*"/>
				</parameters>
			</method>
			<method name="hash" symbol="thunar_vfs_path_hash">
				<return-type type="guint"/>
				<parameters>
					<parameter name="path_ptr" type="gconstpointer"/>
				</parameters>
			</method>
			<method name="is_ancestor" symbol="thunar_vfs_path_is_ancestor">
				<return-type type="gboolean"/>
				<parameters>
					<parameter name="path" type="ThunarVfsPath*"/>
					<parameter name="ancestor" type="ThunarVfsPath*"/>
				</parameters>
			</method>
			<method name="is_home" symbol="thunar_vfs_path_is_home">
				<return-type type="gboolean"/>
				<parameters>
					<parameter name="path" type="ThunarVfsPath*"/>
				</parameters>
			</method>
			<method name="is_root" symbol="thunar_vfs_path_is_root">
				<return-type type="gboolean"/>
				<parameters>
					<parameter name="path" type="ThunarVfsPath*"/>
				</parameters>
			</method>
			<constructor name="new" symbol="thunar_vfs_path_new">
				<return-type type="ThunarVfsPath*"/>
				<parameters>
					<parameter name="identifier" type="gchar*"/>
					<parameter name="error" type="GError**"/>
				</parameters>
			</constructor>
			<method name="ref" symbol="thunar_vfs_path_ref">
				<return-type type="ThunarVfsPath*"/>
				<parameters>
					<parameter name="path" type="ThunarVfsPath*"/>
				</parameters>
			</method>
			<method name="relative" symbol="thunar_vfs_path_relative">
				<return-type type="ThunarVfsPath*"/>
				<parameters>
					<parameter name="parent" type="ThunarVfsPath*"/>
					<parameter name="name" type="gchar*"/>
				</parameters>
			</method>
			<method name="to_string" symbol="thunar_vfs_path_to_string">
				<return-type type="gssize"/>
				<parameters>
					<parameter name="path" type="ThunarVfsPath*"/>
					<parameter name="buffer" type="gchar*"/>
					<parameter name="bufsize" type="gsize"/>
					<parameter name="error" type="GError**"/>
				</parameters>
			</method>
			<method name="to_uri" symbol="thunar_vfs_path_to_uri">
				<return-type type="gssize"/>
				<parameters>
					<parameter name="path" type="ThunarVfsPath*"/>
					<parameter name="buffer" type="gchar*"/>
					<parameter name="bufsize" type="gsize"/>
					<parameter name="error" type="GError**"/>
				</parameters>
			</method>
			<method name="unref" symbol="thunar_vfs_path_unref">
				<return-type type="void"/>
				<parameters>
					<parameter name="path" type="ThunarVfsPath*"/>
				</parameters>
			</method>
			<field name="ref_count" type="gint"/>
			<field name="parent" type="ThunarVfsPath*"/>
		</boxed>
		<boxed name="ThunarVfsPathList" type-name="ThunarVfsPathList" get-type="thunar_vfs_path_list_get_type">
			<method name="append" symbol="thunar_vfs_path_list_append">
				<return-type type="GList*"/>
				<parameters>
					<parameter name="path_list" type="GList*"/>
					<parameter name="path" type="ThunarVfsPath*"/>
				</parameters>
			</method>
			<method name="copy" symbol="thunar_vfs_path_list_copy">
				<return-type type="GList*"/>
				<parameters>
					<parameter name="path_list" type="GList*"/>
				</parameters>
			</method>
			<method name="free" symbol="thunar_vfs_path_list_free">
				<return-type type="void"/>
				<parameters>
					<parameter name="path_list" type="GList*"/>
				</parameters>
			</method>
			<method name="from_string" symbol="thunar_vfs_path_list_from_string">
				<return-type type="GList*"/>
				<parameters>
					<parameter name="uri_string" type="gchar*"/>
					<parameter name="error" type="GError**"/>
				</parameters>
			</method>
			<method name="prepend" symbol="thunar_vfs_path_list_prepend">
				<return-type type="GList*"/>
				<parameters>
					<parameter name="path_list" type="GList*"/>
					<parameter name="path" type="ThunarVfsPath*"/>
				</parameters>
			</method>
			<method name="to_string" symbol="thunar_vfs_path_list_to_string">
				<return-type type="gchar*"/>
				<parameters>
					<parameter name="path_list" type="GList*"/>
				</parameters>
			</method>
		</boxed>
		<enum name="ThunarVfsFileType" type-name="ThunarVfsFileType" get-type="thunar_vfs_file_type_get_type">
			<member name="THUNAR_VFS_FILE_TYPE_PORT" value="14"/>
			<member name="THUNAR_VFS_FILE_TYPE_DOOR" value="13"/>
			<member name="THUNAR_VFS_FILE_TYPE_SOCKET" value="12"/>
			<member name="THUNAR_VFS_FILE_TYPE_SYMLINK" value="10"/>
			<member name="THUNAR_VFS_FILE_TYPE_REGULAR" value="8"/>
			<member name="THUNAR_VFS_FILE_TYPE_BLOCKDEV" value="6"/>
			<member name="THUNAR_VFS_FILE_TYPE_DIRECTORY" value="4"/>
			<member name="THUNAR_VFS_FILE_TYPE_CHARDEV" value="2"/>
			<member name="THUNAR_VFS_FILE_TYPE_FIFO" value="1"/>
			<member name="THUNAR_VFS_FILE_TYPE_UNKNOWN" value="0"/>
		</enum>
		<enum name="ThunarVfsInfoMetadata">
			<member name="THUNAR_VFS_INFO_METADATA_FILE_LINK_TARGET" value="0"/>
			<member name="THUNAR_VFS_INFO_METADATA_TRASH_ORIGINAL_PATH" value="64"/>
			<member name="THUNAR_VFS_INFO_METADATA_TRASH_DELETION_DATE" value="65"/>
		</enum>
		<enum name="ThunarVfsInteractiveJobResponse">
			<member name="THUNAR_VFS_INTERACTIVE_JOB_RESPONSE_YES" value="1"/>
			<member name="THUNAR_VFS_INTERACTIVE_JOB_RESPONSE_YES_ALL" value="2"/>
			<member name="THUNAR_VFS_INTERACTIVE_JOB_RESPONSE_NO" value="4"/>
			<member name="THUNAR_VFS_INTERACTIVE_JOB_RESPONSE_CANCEL" value="8"/>
		</enum>
		<enum name="ThunarVfsMonitorEvent" type-name="ThunarVfsMonitorEvent" get-type="thunar_vfs_monitor_event_get_type">
			<member name="THUNAR_VFS_MONITOR_EVENT_CHANGED" value="0"/>
			<member name="THUNAR_VFS_MONITOR_EVENT_CREATED" value="1"/>
			<member name="THUNAR_VFS_MONITOR_EVENT_DELETED" value="2"/>
		</enum>
		<enum name="ThunarVfsPathScheme">
			<member name="THUNAR_VFS_PATH_SCHEME_FILE" value="0"/>
			<member name="THUNAR_VFS_PATH_SCHEME_TRASH" value="1073741824"/>
			<member name="THUNAR_VFS_PATH_SCHEME_MASK" value="1073741824"/>
		</enum>
		<enum name="ThunarVfsThumbSize" type-name="ThunarVfsThumbSize" get-type="thunar_vfs_thumb_size_get_type">
			<member name="THUNAR_VFS_THUMB_SIZE_NORMAL" value="0"/>
			<member name="THUNAR_VFS_THUMB_SIZE_LARGE" value="1"/>
		</enum>
		<enum name="ThunarVfsVolumeKind" type-name="ThunarVfsVolumeKind" get-type="thunar_vfs_volume_kind_get_type">
			<member name="THUNAR_VFS_VOLUME_KIND_UNKNOWN" value="0"/>
			<member name="THUNAR_VFS_VOLUME_KIND_CDROM" value="1"/>
			<member name="THUNAR_VFS_VOLUME_KIND_CDR" value="2"/>
			<member name="THUNAR_VFS_VOLUME_KIND_CDRW" value="3"/>
			<member name="THUNAR_VFS_VOLUME_KIND_DVDROM" value="4"/>
			<member name="THUNAR_VFS_VOLUME_KIND_DVDRAM" value="5"/>
			<member name="THUNAR_VFS_VOLUME_KIND_DVDR" value="6"/>
			<member name="THUNAR_VFS_VOLUME_KIND_DVDRW" value="7"/>
			<member name="THUNAR_VFS_VOLUME_KIND_DVDPLUSR" value="8"/>
			<member name="THUNAR_VFS_VOLUME_KIND_DVDPLUSRW" value="9"/>
			<member name="THUNAR_VFS_VOLUME_KIND_FLOPPY" value="10"/>
			<member name="THUNAR_VFS_VOLUME_KIND_HARDDISK" value="11"/>
			<member name="THUNAR_VFS_VOLUME_KIND_USBSTICK" value="12"/>
			<member name="THUNAR_VFS_VOLUME_KIND_AUDIO_PLAYER" value="13"/>
			<member name="THUNAR_VFS_VOLUME_KIND_AUDIO_CD" value="14"/>
			<member name="THUNAR_VFS_VOLUME_KIND_MEMORY_CARD" value="15"/>
			<member name="THUNAR_VFS_VOLUME_KIND_REMOVABLE_DISK" value="16"/>
		</enum>
		<flags name="ThunarVfsDeepCountFlags" type-name="ThunarVfsDeepCountFlags" get-type="thunar_vfs_deep_count_flags_get_type">
			<member name="THUNAR_VFS_DEEP_COUNT_FLAGS_NONE" value="0"/>
			<member name="THUNAR_VFS_DEEP_COUNT_FLAGS_FOLLOW_SYMLINKS" value="1"/>
		</flags>
		<flags name="ThunarVfsFileFlags" type-name="ThunarVfsFileFlags" get-type="thunar_vfs_file_flags_get_type">
			<member name="THUNAR_VFS_FILE_FLAGS_NONE" value="0"/>
			<member name="THUNAR_VFS_FILE_FLAGS_SYMLINK" value="1"/>
			<member name="THUNAR_VFS_FILE_FLAGS_EXECUTABLE" value="2"/>
			<member name="THUNAR_VFS_FILE_FLAGS_HIDDEN" value="4"/>
			<member name="THUNAR_VFS_FILE_FLAGS_READABLE" value="8"/>
			<member name="THUNAR_VFS_FILE_FLAGS_WRITABLE" value="16"/>
		</flags>
		<flags name="ThunarVfsFileMode" type-name="ThunarVfsFileMode" get-type="thunar_vfs_file_mode_get_type">
			<member name="THUNAR_VFS_FILE_MODE_SUID" value="2048"/>
			<member name="THUNAR_VFS_FILE_MODE_SGID" value="1024"/>
			<member name="THUNAR_VFS_FILE_MODE_STICKY" value="512"/>
			<member name="THUNAR_VFS_FILE_MODE_USR_ALL" value="448"/>
			<member name="THUNAR_VFS_FILE_MODE_USR_READ" value="256"/>
			<member name="THUNAR_VFS_FILE_MODE_USR_WRITE" value="128"/>
			<member name="THUNAR_VFS_FILE_MODE_USR_EXEC" value="64"/>
			<member name="THUNAR_VFS_FILE_MODE_GRP_ALL" value="56"/>
			<member name="THUNAR_VFS_FILE_MODE_GRP_READ" value="32"/>
			<member name="THUNAR_VFS_FILE_MODE_GRP_WRITE" value="16"/>
			<member name="THUNAR_VFS_FILE_MODE_GRP_EXEC" value="8"/>
			<member name="THUNAR_VFS_FILE_MODE_OTH_ALL" value="7"/>
			<member name="THUNAR_VFS_FILE_MODE_OTH_READ" value="4"/>
			<member name="THUNAR_VFS_FILE_MODE_OTH_WRITE" value="2"/>
			<member name="THUNAR_VFS_FILE_MODE_OTH_EXEC" value="1"/>
		</flags>
		<flags name="ThunarVfsJobResponse" type-name="ThunarVfsJobResponse" get-type="thunar_vfs_job_response_get_type">
			<member name="THUNAR_VFS_JOB_RESPONSE_YES" value="1"/>
			<member name="THUNAR_VFS_JOB_RESPONSE_YES_ALL" value="2"/>
			<member name="THUNAR_VFS_JOB_RESPONSE_NO" value="4"/>
			<member name="THUNAR_VFS_JOB_RESPONSE_CANCEL" value="8"/>
			<member name="THUNAR_VFS_JOB_RESPONSE_NO_ALL" value="16"/>
			<member name="THUNAR_VFS_JOB_RESPONSE_RETRY" value="32"/>
		</flags>
		<flags name="ThunarVfsMimeHandlerFlags" type-name="ThunarVfsMimeHandlerFlags" get-type="thunar_vfs_mime_handler_flags_get_type">
			<member name="THUNAR_VFS_MIME_HANDLER_HIDDEN" value="1"/>
			<member name="THUNAR_VFS_MIME_HANDLER_REQUIRES_TERMINAL" value="2"/>
			<member name="THUNAR_VFS_MIME_HANDLER_SUPPORTS_STARTUP_NOTIFY" value="4"/>
			<member name="THUNAR_VFS_MIME_HANDLER_SUPPORTS_MULTI" value="8"/>
			<member name="THUNAR_VFS_MIME_HANDLER_SUPPORTS_URIS" value="16"/>
		</flags>
		<flags name="ThunarVfsVolumeStatus" type-name="ThunarVfsVolumeStatus" get-type="thunar_vfs_volume_status_get_type">
			<member name="THUNAR_VFS_VOLUME_STATUS_MOUNTED" value="1"/>
			<member name="THUNAR_VFS_VOLUME_STATUS_PRESENT" value="2"/>
			<member name="THUNAR_VFS_VOLUME_STATUS_MOUNTABLE" value="4"/>
		</flags>
		<object name="ThunarVfsGroup" parent="GObject" type-name="ThunarVfsGroup" get-type="thunar_vfs_group_get_type">
			<method name="get_id" symbol="thunar_vfs_group_get_id">
				<return-type type="ThunarVfsGroupId"/>
				<parameters>
					<parameter name="group" type="ThunarVfsGroup*"/>
				</parameters>
			</method>
			<method name="get_name" symbol="thunar_vfs_group_get_name">
				<return-type type="gchar*"/>
				<parameters>
					<parameter name="group" type="ThunarVfsGroup*"/>
				</parameters>
			</method>
		</object>
		<object name="ThunarVfsInteractiveJob" parent="ThunarVfsJob" type-name="ThunarVfsInteractiveJob" get-type="thunar_vfs_interactive_job_get_type">
			<vfunc name="reserved1">
				<return-type type="void"/>
			</vfunc>
			<vfunc name="reserved2">
				<return-type type="void"/>
			</vfunc>
			<vfunc name="reserved3">
				<return-type type="void"/>
			</vfunc>
			<vfunc name="reserved4">
				<return-type type="void"/>
			</vfunc>
			<field name="reserved0" type="guint64"/>
			<field name="reserved1" type="gpointer"/>
			<field name="reserved2" type="guint"/>
			<field name="reserved3" type="guint"/>
		</object>
		<object name="ThunarVfsJob" parent="GObject" type-name="ThunarVfsJob" get-type="thunar_vfs_job_get_type">
			<method name="cancel" symbol="thunar_vfs_job_cancel">
				<return-type type="void"/>
				<parameters>
					<parameter name="job" type="ThunarVfsJob*"/>
				</parameters>
			</method>
			<method name="cancelled" symbol="thunar_vfs_job_cancelled">
				<return-type type="gboolean"/>
				<parameters>
					<parameter name="job" type="ThunarVfsJob*"/>
				</parameters>
			</method>
			<method name="launch" symbol="thunar_vfs_job_launch">
				<return-type type="ThunarVfsJob*"/>
				<parameters>
					<parameter name="job" type="ThunarVfsJob*"/>
				</parameters>
			</method>
			<signal name="ask" when="LAST">
				<return-type type="ThunarVfsJobResponse"/>
				<parameters>
					<parameter name="job" type="ThunarVfsJob*"/>
					<parameter name="message" type="char*"/>
					<parameter name="choices" type="ThunarVfsJobResponse"/>
				</parameters>
			</signal>
			<signal name="ask-replace" when="LAST">
				<return-type type="ThunarVfsJobResponse"/>
				<parameters>
					<parameter name="job" type="ThunarVfsJob*"/>
					<parameter name="src_info" type="ThunarVfsInfo*"/>
					<parameter name="dst_info" type="ThunarVfsInfo*"/>
				</parameters>
			</signal>
			<signal name="error" when="LAST">
				<return-type type="void"/>
				<parameters>
					<parameter name="object" type="ThunarVfsJob*"/>
					<parameter name="p0" type="gpointer"/>
				</parameters>
			</signal>
			<signal name="finished" when="LAST">
				<return-type type="void"/>
				<parameters>
					<parameter name="job" type="ThunarVfsJob*"/>
				</parameters>
			</signal>
			<signal name="info-message" when="LAST">
				<return-type type="void"/>
				<parameters>
					<parameter name="object" type="ThunarVfsJob*"/>
					<parameter name="p0" type="char*"/>
				</parameters>
			</signal>
			<signal name="infos-ready" when="LAST">
				<return-type type="gboolean"/>
				<parameters>
					<parameter name="object" type="ThunarVfsJob*"/>
					<parameter name="p0" type="gpointer"/>
				</parameters>
			</signal>
			<signal name="new-files" when="LAST">
				<return-type type="void"/>
				<parameters>
					<parameter name="object" type="ThunarVfsJob*"/>
					<parameter name="p0" type="gpointer"/>
				</parameters>
			</signal>
			<signal name="percent" when="LAST">
				<return-type type="void"/>
				<parameters>
					<parameter name="object" type="ThunarVfsJob*"/>
					<parameter name="p0" type="gdouble"/>
				</parameters>
			</signal>
			<vfunc name="execute">
				<return-type type="void"/>
				<parameters>
					<parameter name="job" type="ThunarVfsJob*"/>
				</parameters>
			</vfunc>
			<vfunc name="reserved1">
				<return-type type="void"/>
			</vfunc>
			<vfunc name="reserved2">
				<return-type type="void"/>
			</vfunc>
			<field name="cancelled" type="gboolean"/>
		</object>
		<object name="ThunarVfsMimeAction" parent="ThunarVfsMimeHandler" type-name="ThunarVfsMimeAction" get-type="thunar_vfs_mime_action_get_type">
		</object>
		<object name="ThunarVfsMimeApplication" parent="ThunarVfsMimeHandler" type-name="ThunarVfsMimeApplication" get-type="thunar_vfs_mime_application_get_type">
			<method name="equal" symbol="thunar_vfs_mime_application_equal">
				<return-type type="gboolean"/>
				<parameters>
					<parameter name="a" type="gconstpointer"/>
					<parameter name="b" type="gconstpointer"/>
				</parameters>
			</method>
			<method name="get_actions" symbol="thunar_vfs_mime_application_get_actions">
				<return-type type="GList*"/>
				<parameters>
					<parameter name="mime_application" type="ThunarVfsMimeApplication*"/>
				</parameters>
			</method>
			<method name="get_desktop_id" symbol="thunar_vfs_mime_application_get_desktop_id">
				<return-type type="gchar*"/>
				<parameters>
					<parameter name="mime_application" type="ThunarVfsMimeApplication*"/>
				</parameters>
			</method>
			<method name="get_mime_types" symbol="thunar_vfs_mime_application_get_mime_types">
				<return-type type="gchar**"/>
				<parameters>
					<parameter name="mime_application" type="ThunarVfsMimeApplication*"/>
				</parameters>
			</method>
			<method name="hash" symbol="thunar_vfs_mime_application_hash">
				<return-type type="guint"/>
				<parameters>
					<parameter name="mime_application" type="gconstpointer"/>
				</parameters>
			</method>
			<method name="is_usercreated" symbol="thunar_vfs_mime_application_is_usercreated">
				<return-type type="gboolean"/>
				<parameters>
					<parameter name="mime_application" type="ThunarVfsMimeApplication*"/>
				</parameters>
			</method>
			<constructor name="new_from_desktop_id" symbol="thunar_vfs_mime_application_new_from_desktop_id">
				<return-type type="ThunarVfsMimeApplication*"/>
				<parameters>
					<parameter name="desktop_id" type="gchar*"/>
				</parameters>
			</constructor>
			<constructor name="new_from_file" symbol="thunar_vfs_mime_application_new_from_file">
				<return-type type="ThunarVfsMimeApplication*"/>
				<parameters>
					<parameter name="path" type="gchar*"/>
					<parameter name="desktop_id" type="gchar*"/>
				</parameters>
			</constructor>
		</object>
		<object name="ThunarVfsMimeDatabase" parent="GObject" type-name="ThunarVfsMimeDatabase" get-type="thunar_vfs_mime_database_get_type">
			<method name="add_application" symbol="thunar_vfs_mime_database_add_application">
				<return-type type="ThunarVfsMimeApplication*"/>
				<parameters>
					<parameter name="database" type="ThunarVfsMimeDatabase*"/>
					<parameter name="info" type="ThunarVfsMimeInfo*"/>
					<parameter name="name" type="gchar*"/>
					<parameter name="exec" type="gchar*"/>
					<parameter name="error" type="GError**"/>
				</parameters>
			</method>
			<method name="get_applications" symbol="thunar_vfs_mime_database_get_applications">
				<return-type type="GList*"/>
				<parameters>
					<parameter name="database" type="ThunarVfsMimeDatabase*"/>
					<parameter name="info" type="ThunarVfsMimeInfo*"/>
				</parameters>
			</method>
			<method name="get_default" symbol="thunar_vfs_mime_database_get_default">
				<return-type type="ThunarVfsMimeDatabase*"/>
			</method>
			<method name="get_default_application" symbol="thunar_vfs_mime_database_get_default_application">
				<return-type type="ThunarVfsMimeApplication*"/>
				<parameters>
					<parameter name="database" type="ThunarVfsMimeDatabase*"/>
					<parameter name="info" type="ThunarVfsMimeInfo*"/>
				</parameters>
			</method>
			<method name="get_info" symbol="thunar_vfs_mime_database_get_info">
				<return-type type="ThunarVfsMimeInfo*"/>
				<parameters>
					<parameter name="database" type="ThunarVfsMimeDatabase*"/>
					<parameter name="mime_type" type="gchar*"/>
				</parameters>
			</method>
			<method name="get_info_for_data" symbol="thunar_vfs_mime_database_get_info_for_data">
				<return-type type="ThunarVfsMimeInfo*"/>
				<parameters>
					<parameter name="database" type="ThunarVfsMimeDatabase*"/>
					<parameter name="data" type="gconstpointer"/>
					<parameter name="length" type="gsize"/>
				</parameters>
			</method>
			<method name="get_info_for_file" symbol="thunar_vfs_mime_database_get_info_for_file">
				<return-type type="ThunarVfsMimeInfo*"/>
				<parameters>
					<parameter name="database" type="ThunarVfsMimeDatabase*"/>
					<parameter name="path" type="gchar*"/>
					<parameter name="name" type="gchar*"/>
				</parameters>
			</method>
			<method name="get_info_for_name" symbol="thunar_vfs_mime_database_get_info_for_name">
				<return-type type="ThunarVfsMimeInfo*"/>
				<parameters>
					<parameter name="database" type="ThunarVfsMimeDatabase*"/>
					<parameter name="name" type="gchar*"/>
				</parameters>
			</method>
			<method name="get_infos_for_info" symbol="thunar_vfs_mime_database_get_infos_for_info">
				<return-type type="GList*"/>
				<parameters>
					<parameter name="database" type="ThunarVfsMimeDatabase*"/>
					<parameter name="info" type="ThunarVfsMimeInfo*"/>
				</parameters>
			</method>
			<method name="remove_application" symbol="thunar_vfs_mime_database_remove_application">
				<return-type type="gboolean"/>
				<parameters>
					<parameter name="database" type="ThunarVfsMimeDatabase*"/>
					<parameter name="application" type="ThunarVfsMimeApplication*"/>
					<parameter name="error" type="GError**"/>
				</parameters>
			</method>
			<method name="set_default_application" symbol="thunar_vfs_mime_database_set_default_application">
				<return-type type="gboolean"/>
				<parameters>
					<parameter name="database" type="ThunarVfsMimeDatabase*"/>
					<parameter name="info" type="ThunarVfsMimeInfo*"/>
					<parameter name="application" type="ThunarVfsMimeApplication*"/>
					<parameter name="error" type="GError**"/>
				</parameters>
			</method>
		</object>
		<object name="ThunarVfsMimeHandler" parent="GObject" type-name="ThunarVfsMimeHandler" get-type="thunar_vfs_mime_handler_get_type">
			<method name="exec" symbol="thunar_vfs_mime_handler_exec">
				<return-type type="gboolean"/>
				<parameters>
					<parameter name="mime_handler" type="ThunarVfsMimeHandler*"/>
					<parameter name="screen" type="GdkScreen*"/>
					<parameter name="path_list" type="GList*"/>
					<parameter name="error" type="GError**"/>
				</parameters>
			</method>
			<method name="exec_with_env" symbol="thunar_vfs_mime_handler_exec_with_env">
				<return-type type="gboolean"/>
				<parameters>
					<parameter name="mime_handler" type="ThunarVfsMimeHandler*"/>
					<parameter name="screen" type="GdkScreen*"/>
					<parameter name="path_list" type="GList*"/>
					<parameter name="envp" type="gchar**"/>
					<parameter name="error" type="GError**"/>
				</parameters>
			</method>
			<method name="get_command" symbol="thunar_vfs_mime_handler_get_command">
				<return-type type="gchar*"/>
				<parameters>
					<parameter name="mime_handler" type="ThunarVfsMimeHandler*"/>
				</parameters>
			</method>
			<method name="get_flags" symbol="thunar_vfs_mime_handler_get_flags">
				<return-type type="ThunarVfsMimeHandlerFlags"/>
				<parameters>
					<parameter name="mime_handler" type="ThunarVfsMimeHandler*"/>
				</parameters>
			</method>
			<method name="get_name" symbol="thunar_vfs_mime_handler_get_name">
				<return-type type="gchar*"/>
				<parameters>
					<parameter name="mime_handler" type="ThunarVfsMimeHandler*"/>
				</parameters>
			</method>
			<method name="lookup_icon_name" symbol="thunar_vfs_mime_handler_lookup_icon_name">
				<return-type type="gchar*"/>
				<parameters>
					<parameter name="mime_handler" type="ThunarVfsMimeHandler*"/>
					<parameter name="icon_theme" type="GtkIconTheme*"/>
				</parameters>
			</method>
			<property name="command" type="char*" readable="1" writable="1" construct="0" construct-only="1"/>
			<property name="flags" type="ThunarVfsMimeHandlerFlags" readable="1" writable="1" construct="0" construct-only="1"/>
			<property name="icon" type="char*" readable="1" writable="1" construct="0" construct-only="1"/>
			<property name="name" type="char*" readable="1" writable="1" construct="0" construct-only="1"/>
		</object>
		<object name="ThunarVfsMonitor" parent="GObject" type-name="ThunarVfsMonitor" get-type="thunar_vfs_monitor_get_type">
			<method name="add_directory" symbol="thunar_vfs_monitor_add_directory">
				<return-type type="ThunarVfsMonitorHandle*"/>
				<parameters>
					<parameter name="monitor" type="ThunarVfsMonitor*"/>
					<parameter name="path" type="ThunarVfsPath*"/>
					<parameter name="callback" type="ThunarVfsMonitorCallback"/>
					<parameter name="user_data" type="gpointer"/>
				</parameters>
			</method>
			<method name="add_file" symbol="thunar_vfs_monitor_add_file">
				<return-type type="ThunarVfsMonitorHandle*"/>
				<parameters>
					<parameter name="monitor" type="ThunarVfsMonitor*"/>
					<parameter name="path" type="ThunarVfsPath*"/>
					<parameter name="callback" type="ThunarVfsMonitorCallback"/>
					<parameter name="user_data" type="gpointer"/>
				</parameters>
			</method>
			<method name="feed" symbol="thunar_vfs_monitor_feed">
				<return-type type="void"/>
				<parameters>
					<parameter name="monitor" type="ThunarVfsMonitor*"/>
					<parameter name="event" type="ThunarVfsMonitorEvent"/>
					<parameter name="path" type="ThunarVfsPath*"/>
				</parameters>
			</method>
			<method name="get_default" symbol="thunar_vfs_monitor_get_default">
				<return-type type="ThunarVfsMonitor*"/>
			</method>
			<method name="remove" symbol="thunar_vfs_monitor_remove">
				<return-type type="void"/>
				<parameters>
					<parameter name="monitor" type="ThunarVfsMonitor*"/>
					<parameter name="handle" type="ThunarVfsMonitorHandle*"/>
				</parameters>
			</method>
			<method name="wait" symbol="thunar_vfs_monitor_wait">
				<return-type type="void"/>
				<parameters>
					<parameter name="monitor" type="ThunarVfsMonitor*"/>
				</parameters>
			</method>
		</object>
		<object name="ThunarVfsThumbFactory" parent="GObject" type-name="ThunarVfsThumbFactory" get-type="thunar_vfs_thumb_factory_get_type">
			<method name="can_thumbnail" symbol="thunar_vfs_thumb_factory_can_thumbnail">
				<return-type type="gboolean"/>
				<parameters>
					<parameter name="factory" type="ThunarVfsThumbFactory*"/>
					<parameter name="info" type="ThunarVfsInfo*"/>
				</parameters>
			</method>
			<method name="generate_thumbnail" symbol="thunar_vfs_thumb_factory_generate_thumbnail">
				<return-type type="GdkPixbuf*"/>
				<parameters>
					<parameter name="factory" type="ThunarVfsThumbFactory*"/>
					<parameter name="info" type="ThunarVfsInfo*"/>
				</parameters>
			</method>
			<method name="has_failed_thumbnail" symbol="thunar_vfs_thumb_factory_has_failed_thumbnail">
				<return-type type="gboolean"/>
				<parameters>
					<parameter name="factory" type="ThunarVfsThumbFactory*"/>
					<parameter name="info" type="ThunarVfsInfo*"/>
				</parameters>
			</method>
			<method name="lookup_thumbnail" symbol="thunar_vfs_thumb_factory_lookup_thumbnail">
				<return-type type="gchar*"/>
				<parameters>
					<parameter name="factory" type="ThunarVfsThumbFactory*"/>
					<parameter name="info" type="ThunarVfsInfo*"/>
				</parameters>
			</method>
			<constructor name="new" symbol="thunar_vfs_thumb_factory_new">
				<return-type type="ThunarVfsThumbFactory*"/>
				<parameters>
					<parameter name="size" type="ThunarVfsThumbSize"/>
				</parameters>
			</constructor>
			<method name="store_thumbnail" symbol="thunar_vfs_thumb_factory_store_thumbnail">
				<return-type type="gboolean"/>
				<parameters>
					<parameter name="factory" type="ThunarVfsThumbFactory*"/>
					<parameter name="pixbuf" type="GdkPixbuf*"/>
					<parameter name="info" type="ThunarVfsInfo*"/>
					<parameter name="error" type="GError**"/>
				</parameters>
			</method>
			<property name="size" type="ThunarVfsThumbSize" readable="1" writable="1" construct="0" construct-only="1"/>
		</object>
		<object name="ThunarVfsUser" parent="GObject" type-name="ThunarVfsUser" get-type="thunar_vfs_user_get_type">
			<method name="get_groups" symbol="thunar_vfs_user_get_groups">
				<return-type type="GList*"/>
				<parameters>
					<parameter name="user" type="ThunarVfsUser*"/>
				</parameters>
			</method>
			<method name="get_id" symbol="thunar_vfs_user_get_id">
				<return-type type="ThunarVfsUserId"/>
				<parameters>
					<parameter name="user" type="ThunarVfsUser*"/>
				</parameters>
			</method>
			<method name="get_name" symbol="thunar_vfs_user_get_name">
				<return-type type="gchar*"/>
				<parameters>
					<parameter name="user" type="ThunarVfsUser*"/>
				</parameters>
			</method>
			<method name="get_primary_group" symbol="thunar_vfs_user_get_primary_group">
				<return-type type="ThunarVfsGroup*"/>
				<parameters>
					<parameter name="user" type="ThunarVfsUser*"/>
				</parameters>
			</method>
			<method name="get_real_name" symbol="thunar_vfs_user_get_real_name">
				<return-type type="gchar*"/>
				<parameters>
					<parameter name="user" type="ThunarVfsUser*"/>
				</parameters>
			</method>
			<method name="is_me" symbol="thunar_vfs_user_is_me">
				<return-type type="gboolean"/>
				<parameters>
					<parameter name="user" type="ThunarVfsUser*"/>
				</parameters>
			</method>
		</object>
		<object name="ThunarVfsUserManager" parent="GObject" type-name="ThunarVfsUserManager" get-type="thunar_vfs_user_manager_get_type">
			<method name="get_all_groups" symbol="thunar_vfs_user_manager_get_all_groups">
				<return-type type="GList*"/>
				<parameters>
					<parameter name="manager" type="ThunarVfsUserManager*"/>
				</parameters>
			</method>
			<method name="get_default" symbol="thunar_vfs_user_manager_get_default">
				<return-type type="ThunarVfsUserManager*"/>
			</method>
			<method name="get_group_by_id" symbol="thunar_vfs_user_manager_get_group_by_id">
				<return-type type="ThunarVfsGroup*"/>
				<parameters>
					<parameter name="manager" type="ThunarVfsUserManager*"/>
					<parameter name="id" type="ThunarVfsGroupId"/>
				</parameters>
			</method>
			<method name="get_user_by_id" symbol="thunar_vfs_user_manager_get_user_by_id">
				<return-type type="ThunarVfsUser*"/>
				<parameters>
					<parameter name="manager" type="ThunarVfsUserManager*"/>
					<parameter name="id" type="ThunarVfsUserId"/>
				</parameters>
			</method>
		</object>
		<object name="ThunarVfsVolume" parent="GObject" type-name="ThunarVfsVolume" get-type="thunar_vfs_volume_get_type">
			<method name="eject" symbol="thunar_vfs_volume_eject">
				<return-type type="gboolean"/>
				<parameters>
					<parameter name="volume" type="ThunarVfsVolume*"/>
					<parameter name="window" type="GtkWidget*"/>
					<parameter name="error" type="GError**"/>
				</parameters>
			</method>
			<method name="get_kind" symbol="thunar_vfs_volume_get_kind">
				<return-type type="ThunarVfsVolumeKind"/>
				<parameters>
					<parameter name="volume" type="ThunarVfsVolume*"/>
				</parameters>
			</method>
			<method name="get_mount_point" symbol="thunar_vfs_volume_get_mount_point">
				<return-type type="ThunarVfsPath*"/>
				<parameters>
					<parameter name="volume" type="ThunarVfsVolume*"/>
				</parameters>
			</method>
			<method name="get_name" symbol="thunar_vfs_volume_get_name">
				<return-type type="gchar*"/>
				<parameters>
					<parameter name="volume" type="ThunarVfsVolume*"/>
				</parameters>
			</method>
			<method name="get_status" symbol="thunar_vfs_volume_get_status">
				<return-type type="ThunarVfsVolumeStatus"/>
				<parameters>
					<parameter name="volume" type="ThunarVfsVolume*"/>
				</parameters>
			</method>
			<method name="is_disc" symbol="thunar_vfs_volume_is_disc">
				<return-type type="gboolean"/>
				<parameters>
					<parameter name="volume" type="ThunarVfsVolume*"/>
				</parameters>
			</method>
			<method name="is_ejectable" symbol="thunar_vfs_volume_is_ejectable">
				<return-type type="gboolean"/>
				<parameters>
					<parameter name="volume" type="ThunarVfsVolume*"/>
				</parameters>
			</method>
			<method name="is_mountable" symbol="thunar_vfs_volume_is_mountable">
				<return-type type="gboolean"/>
				<parameters>
					<parameter name="volume" type="ThunarVfsVolume*"/>
				</parameters>
			</method>
			<method name="is_mounted" symbol="thunar_vfs_volume_is_mounted">
				<return-type type="gboolean"/>
				<parameters>
					<parameter name="volume" type="ThunarVfsVolume*"/>
				</parameters>
			</method>
			<method name="is_present" symbol="thunar_vfs_volume_is_present">
				<return-type type="gboolean"/>
				<parameters>
					<parameter name="volume" type="ThunarVfsVolume*"/>
				</parameters>
			</method>
			<method name="is_removable" symbol="thunar_vfs_volume_is_removable">
				<return-type type="gboolean"/>
				<parameters>
					<parameter name="volume" type="ThunarVfsVolume*"/>
				</parameters>
			</method>
			<method name="lookup_icon_name" symbol="thunar_vfs_volume_lookup_icon_name">
				<return-type type="gchar*"/>
				<parameters>
					<parameter name="volume" type="ThunarVfsVolume*"/>
					<parameter name="icon_theme" type="GtkIconTheme*"/>
				</parameters>
			</method>
			<method name="mount" symbol="thunar_vfs_volume_mount">
				<return-type type="gboolean"/>
				<parameters>
					<parameter name="volume" type="ThunarVfsVolume*"/>
					<parameter name="window" type="GtkWidget*"/>
					<parameter name="error" type="GError**"/>
				</parameters>
			</method>
			<method name="unmount" symbol="thunar_vfs_volume_unmount">
				<return-type type="gboolean"/>
				<parameters>
					<parameter name="volume" type="ThunarVfsVolume*"/>
					<parameter name="window" type="GtkWidget*"/>
					<parameter name="error" type="GError**"/>
				</parameters>
			</method>
			<signal name="changed" when="LAST">
				<return-type type="void"/>
				<parameters>
					<parameter name="object" type="ThunarVfsVolume*"/>
				</parameters>
			</signal>
			<signal name="mounted" when="LAST">
				<return-type type="void"/>
				<parameters>
					<parameter name="object" type="ThunarVfsVolume*"/>
				</parameters>
			</signal>
			<signal name="pre-unmount" when="LAST">
				<return-type type="void"/>
				<parameters>
					<parameter name="object" type="ThunarVfsVolume*"/>
				</parameters>
			</signal>
			<signal name="unmounted" when="LAST">
				<return-type type="void"/>
				<parameters>
					<parameter name="object" type="ThunarVfsVolume*"/>
				</parameters>
			</signal>
		</object>
		<object name="ThunarVfsVolumeManager" parent="GObject" type-name="ThunarVfsVolumeManager" get-type="thunar_vfs_volume_manager_get_type">
			<method name="get_default" symbol="thunar_vfs_volume_manager_get_default">
				<return-type type="ThunarVfsVolumeManager*"/>
			</method>
			<method name="get_volume_by_info" symbol="thunar_vfs_volume_manager_get_volume_by_info">
				<return-type type="ThunarVfsVolume*"/>
				<parameters>
					<parameter name="manager" type="ThunarVfsVolumeManager*"/>
					<parameter name="info" type="ThunarVfsInfo*"/>
				</parameters>
			</method>
			<method name="get_volumes" symbol="thunar_vfs_volume_manager_get_volumes">
				<return-type type="GList*"/>
				<parameters>
					<parameter name="manager" type="ThunarVfsVolumeManager*"/>
				</parameters>
			</method>
			<signal name="volume-mounted" when="LAST">
				<return-type type="void"/>
				<parameters>
					<parameter name="object" type="ThunarVfsVolumeManager*"/>
					<parameter name="p0" type="ThunarVfsVolume*"/>
				</parameters>
			</signal>
			<signal name="volume-pre-unmount" when="LAST">
				<return-type type="void"/>
				<parameters>
					<parameter name="object" type="ThunarVfsVolumeManager*"/>
					<parameter name="p0" type="ThunarVfsVolume*"/>
				</parameters>
			</signal>
			<signal name="volume-unmounted" when="LAST">
				<return-type type="void"/>
				<parameters>
					<parameter name="object" type="ThunarVfsVolumeManager*"/>
					<parameter name="p0" type="ThunarVfsVolume*"/>
				</parameters>
			</signal>
			<signal name="volumes-added" when="LAST">
				<return-type type="void"/>
				<parameters>
					<parameter name="object" type="ThunarVfsVolumeManager*"/>
					<parameter name="p0" type="gpointer"/>
				</parameters>
			</signal>
			<signal name="volumes-removed" when="LAST">
				<return-type type="void"/>
				<parameters>
					<parameter name="object" type="ThunarVfsVolumeManager*"/>
					<parameter name="p0" type="gpointer"/>
				</parameters>
			</signal>
		</object>
		<constant name="THUNAR_VFS_MAJOR_VERSION" type="int" value="0"/>
		<constant name="THUNAR_VFS_MICRO_VERSION" type="int" value="0"/>
		<constant name="THUNAR_VFS_MINOR_VERSION" type="int" value="9"/>
		<constant name="THUNAR_VFS_PATH_MAXSTRLEN" type="int" value="1"/>
		<constant name="THUNAR_VFS_PATH_MAXURILEN" type="int" value="-2"/>
	</namespace>
</api>
