/*
 * Desktop Agnostic Library: Icon chooser dialog.
 *
 * Copyright (C) 2009 Mark Lee <libdesktop-agnostic@lazymalevolence.com>
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA
 *
 * Author : Mark Lee <libdesktop-agnostic@lazymalevolence.com>
 */

using DesktopAgnostic;
using Gtk;

// make sure GETTEXT_PACKAGE is defined.
private const string ICON_I18N_PACKAGE = Build.GETTEXT_PACKAGE;

namespace DesktopAgnostic.GTK
{
  public enum IconType
  {
    NONE,
    THEMED,
    FILE
  }

  public class IconChooserDialog : Dialog
  {
    private RadioButton _file;
    private RadioButton _themed;
    private FileChooserButton _directory;
    private ComboBox _themed_context;
    private IconView _file_viewer;
    private IconView? _themed_viewer = null;
    private unowned IconView _viewer;
    public string selected_icon { get; private set; default = null; }
    public Gdk.Pixbuf selected_pixbuf { get; private set; default = null; }
    public IconType selected_icon_type { get; private set; default = IconType.NONE; }

    private enum Column
    {
      PIXBUF,
      NAME,
      DATA,
      COUNT
    }

    public signal void icon_selected ();

    construct
    {
      this.response.connect (this.on_response);
      this.title = _ ("Select Icon");
      this.icon_name = STOCK_FIND;
      this.create_ui ();
    }

    private void
    create_ui ()
    {
      HBox choices;

      choices = new HBox (false, 5);
      this._file = new RadioButton.with_mnemonic (null, _ ("From File"));
      choices.add (this._file);
      this._themed = new RadioButton.with_mnemonic_from_widget (this._file,
                                                                _ ("From Theme"));
      this._themed.active = false;
      this._themed.toggled.connect (this.on_icon_type_toggled);
      choices.add (this._themed);
      this.vbox.pack_start (choices, false, false, 5);
      choices.show_all ();

      this._directory = new FileChooserButton (_ ("Select icon folder"),
                                               FileChooserAction.SELECT_FOLDER);
      this._directory.current_folder_changed.connect (this.on_folder_changed);
      this.vbox.pack_start (this._directory, false, false, 5);
      this._directory.show ();

      this.add_icon_viewer (ref this._file_viewer, false);
      this._file_viewer.parent.show_all ();
      this._viewer = this._file_viewer;

      this.on_folder_changed (this._directory);

      this.add_buttons (STOCK_CANCEL, ResponseType.CANCEL,
                        STOCK_OK, ResponseType.OK);
    }

    private void
    add_icon_viewer (ref IconView viewer, bool themed)
    {
      ScrolledWindow scrolled;

      scrolled = new ScrolledWindow (null, null);
      scrolled.set_policy (PolicyType.NEVER, PolicyType.AUTOMATIC);
      viewer = this.create_icon_viewer (themed);
      viewer.show ();
      scrolled.add (viewer);
      this.vbox.pack_start (scrolled, true, true, 5);
    }

    private IconView
    create_icon_viewer (bool themed)
    {
      IconView viewer;
      CellRendererPixbuf cell_pixbuf;
      CellRendererText cell_text;

      viewer = new IconView.with_model (this.create_model ());
      viewer.item_width = 72;
      viewer.columns = 4;
      viewer.column_spacing = 5;
      viewer.set_size_request (325, 300);
      viewer.tooltip_column = Column.DATA;
      cell_pixbuf = new CellRendererPixbuf ();
      cell_pixbuf.xalign = 0.5f;
      cell_pixbuf.yalign = 0.5f;
      cell_pixbuf.width = 48;
      viewer.pack_start (cell_pixbuf, false);
      viewer.add_attribute (cell_pixbuf, "pixbuf", Column.PIXBUF);
      cell_text = new CellRendererText ();
      cell_text.xalign = 0.5f;
      cell_text.yalign = 0;
      cell_text.wrap_mode = Pango.WrapMode.WORD;
      cell_text.wrap_width = 72;
      cell_text.width = 72;
      cell_text.ellipsize = Pango.EllipsizeMode.START;
      viewer.pack_start (cell_text, true);
      viewer.add_attribute (cell_text, "text", 1);
      viewer.selection_mode = SelectionMode.SINGLE;

      return viewer;
    }

    private ListStore
    create_model ()
    {
      // icon, name, data
      return new ListStore (Column.COUNT, typeof (Gdk.Pixbuf), typeof (string),
                            typeof (string));
    }

    private void
    on_icon_type_toggled (ToggleButton themed)
    {
      if (this._themed.active)
      {
        if (this._themed_viewer == null)
        {
          unowned IconTheme icon_theme;
          unowned List<string> context_list;

          this._themed_context = new ComboBox.text ();
          this._themed_context.changed.connect (this.on_icon_context_changed);
          this.vbox.pack_start (this._themed_context, false, false, 5);

          this.add_icon_viewer (ref this._themed_viewer, true);

          icon_theme = IconTheme.get_default ();
          context_list = icon_theme.list_contexts ();
          context_list.sort ((CompareFunc)strcmp);
          foreach (unowned string context in context_list)
          {
            this._themed_context.append_text (context);
          }
        }
        this._file_viewer.parent.hide ();
        this._directory.hide ();
        this._themed_viewer.parent.show ();
        this._themed_context.show ();
        this._viewer = this._themed_viewer;
      }
      else
      {
        this._themed_viewer.parent.hide ();
        this._themed_context.hide ();
        this._file_viewer.parent.show ();
        this._directory.show ();
        this._viewer = this._file_viewer;
      }
    }

    private void
    on_folder_changed (FileChooser chooser)
    {
      unowned ListStore model;
      string uri;
      VFS.File directory;
      SList<VFS.File> children;

      model = this._file_viewer.model as ListStore;
      model.clear ();

      uri = chooser.get_uri ();
      directory = VFS.file_new_for_uri (uri);
      children = directory.enumerate_children ();
      foreach (unowned VFS.File child in children)
      {
        string path;

        path = child.path.down ();
        if (path.has_suffix (".png") || path.has_suffix (".svg") ||
            path.has_suffix (".jpg") || path.has_suffix (".jpeg") ||
            path.has_suffix (".xpm"))
        {
          try
          {
            TreeIter iter;
            Gdk.Pixbuf pixbuf;

            pixbuf = new Gdk.Pixbuf.from_file_at_scale (path, 48, -1, true);

            model.append (out iter);
            model.set (iter, Column.PIXBUF, pixbuf,
                       Column.NAME, Path.get_basename (path),
                       Column.DATA, path);
          }
          catch (FileError err)
          {
            // ignore
          }
          catch (Error err)
          {
            warning ("GDK Pixbuf error (%s): %s", path, err.message);
          }
        }
      }
    }

    private void
    on_icon_context_changed (ComboBox box)
    {
      unowned ListStore model;
      unowned IconTheme icon_theme;
      unowned List<string> icon_list;

      model = this._themed_viewer.model as ListStore;
      model.clear ();

      icon_theme = IconTheme.get_default ();
      icon_list = icon_theme.list_icons (box.get_active_text ());
      icon_list.sort ((CompareFunc)strcmp);
      foreach (unowned string icon_name in icon_list)
      {
        try
        {
          IconInfo info;
          Gdk.Pixbuf pixbuf;
          string? name;
          TreeIter iter;

          info = icon_theme.lookup_icon (icon_name, 48, 0);
          pixbuf = info.load_icon ();
          name = info.get_display_name ();
          if (name == null)
          {
            name = icon_name.replace ("-", " ");
          }
          model.append (out iter);
          model.set (iter, Column.PIXBUF, pixbuf,
                     Column.NAME, name,
                     Column.DATA, icon_name);
        }
        catch (Error err)
        {
          warning ("Could not load %s: %s", icon_name, err.message);
        }
      }
    }

    private void
    on_response (int response)
    {
      if (response == ResponseType.OK)
      {
        unowned List<TreePath>? item;

        item = this._viewer.get_selected_items ();
        if (item == null)
        {
          string msg;
          MessageDialog dialog;

          msg = _ ("Please select an icon.");
          dialog = new MessageDialog (this, DialogFlags.MODAL, MessageType.ERROR,
                                      ButtonsType.OK, msg);
          dialog.title = _ ("Error");
          dialog.run ();
          dialog.destroy ();
          return;
        }
        else
        {
          TreePath path;
          TreeModel model;
          bool res;
          TreeIter iter;

          path = item.data;
          model = this._viewer.model;

          res = model.get_iter (out iter, path);
          if (res)
          {
            Value pixbuf;
            Value data;

            model.get_value (iter, Column.PIXBUF, out pixbuf);
            model.get_value (iter, Column.DATA, out data);
            this.selected_pixbuf = (Gdk.Pixbuf)pixbuf;
            this.selected_icon = (string)data;

            if (this._viewer == this._file_viewer)
            {
              this.selected_icon_type = IconType.FILE;
            }
            else
            {
              this.selected_icon_type = IconType.THEMED;
            }

            this.icon_selected ();
          }
          else
          {
            warning ("Something wrong happened when converting tree path -> iter.");
          }
        }
      }
      this.hide ();
    }
  }
}

// vim:et:ai:cindent:ts=2 sts=2 sw=2
