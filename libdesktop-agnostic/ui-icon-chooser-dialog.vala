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

namespace DesktopAgnostic.UI
{
  public enum IconType
  {
    NONE,
    THEMED,
    FILE
  }

  private class LazyPixbufRenderer : CellRendererPixbuf
  {
    public bool item_ready { get; set; default = false; }

    public signal void prepare_pixbuf (TreePath path);

    public override void render (Gdk.Window window,
                                 Gtk.Widget widget,
                                 Gdk.Rectangle background_area,
                                 Gdk.Rectangle cell_area,
                                 Gdk.Rectangle expose_area,
                                 Gtk.CellRendererState flags)
    {
      if (!item_ready)
      {
        int x, y;
        var view = widget as Gtk.IconView;
        x = cell_area.x + cell_area.width / 2;
        y = cell_area.y + cell_area.height / 2;
        var path = view.get_path_at_pos (x, y);
        prepare_pixbuf (path);
      }
      base.render (window, widget,
                   background_area, cell_area, expose_area, flags);
    }
  }

  public class IconChooserDialog : Dialog
  {
    private RadioButton _file;
    private RadioButton _themed;
    private FileChooserButton _directory;
    private ComboBox _themed_context;
    private IconView? _file_viewer = null;
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
      PIXBUF_READY,
      COUNT
    }

    public signal void icon_selected ();

    private static Gdk.Pixbuf NO_ICON;

    static construct
    {
      var flags = IconLookupFlags.FORCE_SIZE | IconLookupFlags.GENERIC_FALLBACK;
      NO_ICON = IconTheme.get_default ().load_icon ("gtk-file", 48, flags);
    }

    construct
    {
      this.response.connect (this.on_response);
      this.title = _ ("Select Icon");
      this.icon_name = STOCK_FIND;
      this.set_default_size (375, 375);
      this.create_ui ();
    }

    private void
    create_ui ()
    {
      HBox choices;

      choices = new HBox (false, 5);
      this._themed = new RadioButton.with_mnemonic (null, _ ("From Theme"));
      choices.add (this._themed);
      this._file = new RadioButton.with_mnemonic_from_widget (this._themed,
                                                              _ ("From File"));
      this._themed.active = true;
      this._themed.toggled.connect (this.on_icon_type_toggled);
      choices.add (this._file);
      this.vbox.pack_start (choices, false, false, 5);
      choices.show_all ();

      this.on_icon_type_toggled ();

      this.add_buttons (STOCK_CANCEL, ResponseType.CANCEL,
                        STOCK_OK, ResponseType.OK);
    }

    private void
    add_icon_viewer (out IconView viewer, bool themed)
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
      LazyPixbufRenderer cell_pixbuf;
      CellRendererText cell_text;

      viewer = new IconView.with_model (this.create_model ());
      // without this the IconView is not shrinkable after expanding it
      viewer.set_size_request (108, -1);
      viewer.set_item_width (108);
      viewer.set_column_spacing (5);
      viewer.set_tooltip_column (Column.DATA);

      cell_pixbuf = new LazyPixbufRenderer ();
      cell_pixbuf.xalign = 0.5f;
      cell_pixbuf.yalign = 0.5f;
      cell_pixbuf.width = 48;

      viewer.pack_start (cell_pixbuf, false);
      viewer.add_attribute (cell_pixbuf, "pixbuf", Column.PIXBUF);
      viewer.add_attribute (cell_pixbuf, "item-ready", Column.PIXBUF_READY);

      cell_pixbuf.prepare_pixbuf.connect ((p) =>
      {
        TreeIter iter;
        Value val;
        var store = this._viewer.model as ListStore;
        store.get_iter (out iter, p);
        store.get_value (iter, Column.DATA, out val);

        string icon_name = val.get_string ();
        IconTheme icon_theme = IconTheme.get_default ();
        var info = icon_theme.lookup_icon (icon_name, 48, 0);
        string? name = info.get_display_name ();
        if (name == null)
        {
          name = icon_name.replace ("-", " ");
        }
        try
        {
          var pixbuf = info.load_icon ();
          store.set (iter, Column.NAME, name, Column.PIXBUF, pixbuf,
                     Column.PIXBUF_READY, true, -1);
        }
        catch (Error err)
        {
          warning ("Could not load %s: %s", icon_name, err.message);
          store.set (iter, Column.NAME, name, Column.PIXBUF_READY, true, -1);
        }
      });

      cell_text = new CellRendererText ();
      cell_text.xalign = 0.5f;
      cell_text.yalign = 0.0f;
      cell_text.wrap_mode = Pango.WrapMode.WORD;
      int wrap_width = viewer.item_width - viewer.item_padding * 2;
      cell_text.wrap_width = wrap_width;
      cell_text.width = wrap_width;
      cell_text.ellipsize = Pango.EllipsizeMode.MIDDLE;
      viewer.pack_start (cell_text, true);
      viewer.add_attribute (cell_text, "text", Column.NAME);
      viewer.selection_mode = SelectionMode.SINGLE;

      return viewer;
    }

    private ListStore
    create_model ()
    {
      // icon, name, data
      return new ListStore (Column.COUNT,
                            typeof (Gdk.Pixbuf),
                            typeof (string),
                            typeof (string),
                            typeof (bool));
    }

    private void
    on_icon_type_toggled ()
    {
      if (this._themed.active)
      {
        if (this._themed_viewer == null)
        {
          unowned IconTheme icon_theme;
          List<string> context_list;

          // "From Theme" widgets -> context combobox + icon view
          this._themed_context = new ComboBox.text ();
          this._themed_context.changed.connect (this.on_icon_context_changed);
          this.vbox.pack_start (this._themed_context, false, false, 5);

          this.add_icon_viewer (out this._themed_viewer, true);

          icon_theme = IconTheme.get_default ();
          context_list = icon_theme.list_contexts ();
          context_list.sort ((CompareFunc)strcmp);

          int active_index = 0;
          int cur_index = 0;
          foreach (unowned string context in context_list)
          {
            this._themed_context.append_text (context);
            // try to make "Applications" context active by default
            if (context == "Applications")
            {
              active_index = cur_index;
            }
            cur_index++;
          }
          this._themed_context.set_active (active_index);
        }

        if (this._file_viewer != null)
        {
          this._file_viewer.parent.hide ();
          this._directory.hide ();
        }
        this._themed_viewer.parent.show ();
        this._themed_context.show ();
        this._viewer = this._themed_viewer;
      }
      else
      {
        if (this._file_viewer == null)
        {
          // "From File" widgets -> directory chooser + icon view
          this._directory = new FileChooserButton (_ ("Select icon folder"),
                                                   FileChooserAction.SELECT_FOLDER);
          this._directory.current_folder_changed.connect (this.on_folder_changed);
          this.vbox.pack_start (this._directory, false, false, 5);
          this._directory.show ();

          this.add_icon_viewer (out this._file_viewer, false);

          this.on_folder_changed (this._directory);
        }

        if (this._themed_viewer != null)
        {
          this._themed_viewer.parent.hide ();
          this._themed_context.hide ();
        }
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
        string path_down;

        path = child.path;
        path_down = path.down ();
        if (path_down.has_suffix (".png") || path_down.has_suffix (".svg") ||
            path_down.has_suffix (".jpg") || path_down.has_suffix (".jpeg") ||
            path_down.has_suffix (".xpm"))
        {
          try
          {
            TreeIter iter;
            Gdk.Pixbuf pixbuf;

            pixbuf = new Gdk.Pixbuf.from_file_at_scale (path, 48, -1, true);

            model.append (out iter);
            model.set (iter,
                       Column.PIXBUF, pixbuf,
                       Column.PIXBUF_READY, true,
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
      List<string> icon_list;

      model = this._themed_viewer.model as ListStore;
      model.clear ();

      icon_theme = IconTheme.get_default ();
      icon_list = icon_theme.list_icons (box.get_active_text ());
      icon_list.sort ((CompareFunc)strcmp);
      foreach (unowned string icon_name in icon_list)
      {
        TreeIter iter;

        model.append (out iter);
        model.set (iter,
                   Column.PIXBUF, NO_ICON,
                   Column.PIXBUF_READY, false,
                   Column.NAME, icon_name,
                   Column.DATA, icon_name);
      }
    }

    private void
    on_response (int response)
    {
      if (response == ResponseType.OK)
      {
        List<TreePath>? item;

        item = this._viewer.get_selected_items ();
        if (item == null)
        {
          string msg;
          MessageDialog dialog;

          msg = _ ("Please select an icon.");
          dialog = new MessageDialog (this, DialogFlags.MODAL, MessageType.ERROR,
                                      ButtonsType.OK, "%s", msg);
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
