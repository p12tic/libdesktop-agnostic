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
using DesktopAgnostic.FDO;
using Gtk;

// make sure GETTEXT_PACKAGE is defined.
private const string LAUNCHER_I18N_PACKAGE = Build.GETTEXT_PACKAGE;

namespace DesktopAgnostic.UI
{
  private class FixedTable : Table
  {
    public FixedTable (uint columns, uint rows)
    {
      this.n_columns = columns;
      this.n_rows = rows;
      this.homogeneous = false;
    }

    public new void
    attach_defaults (Widget widget, uint left_attach, uint right_attach,
                     uint top_attach, uint bottom_attach)
    {
      this.attach (widget, left_attach, right_attach, top_attach, bottom_attach,
                   AttachOptions.FILL, AttachOptions.SHRINK, 0, 0);
    }

    public void
    attach_fill (Widget widget, uint left_attach, uint right_attach,
                 uint top_attach, uint bottom_attach)
    {
      this.attach (widget, left_attach, right_attach, top_attach, bottom_attach,
                   AttachOptions.FILL, 0, 0, 0);
    }
  }

  public class LauncherEditorDialog : Dialog
  {
    private IconButton _icon;
    private Entry _name;
    private Entry _desc;
    private Entry _exec;
    private CheckButton _terminal;
    private CheckButton _startup_notification;
    public unowned VFS.File file { get; construct; }
    public VFS.File? output { get; construct; }
    private bool _standalone;
    private DesktopEntry _entry;

    public LauncherEditorDialog (VFS.File file, VFS.File? output, bool standalone)
    {
      GLib.Object (type: standalone ? WindowType.TOPLEVEL : WindowType.POPUP,
                   file: file, output: output);
      this._standalone = standalone;
    }

    private override void
    constructed ()
    {
      this.title = _ ("Desktop Entry Editor");
      this.icon_name = "gtk-preferences";
      if (this._standalone)
      {
        this.delete_event.connect((widget, event) => {
          main_quit ();
          return true;
        });
      }
      if (this._output == null)
      {
        this._output = file;
      }
      this._entry = desktop_entry_new_for_file (file);
      this.build_ui ();
    }

    private void
    build_ui ()
    {
      FixedTable table;
      string icon;
      Button exec_button;
      Image exec_image;
      Label name_label, desc_label, exec_label;
      HBox exec_hbox;
      Expander advanced;
      VBox advanced_vbox;

      // Action bar
      this.add_buttons (STOCK_CANCEL, ResponseType.CANCEL,
                        STOCK_SAVE, ResponseType.APPLY);
      this.set_default_response (ResponseType.CANCEL);
      this.response.connect (this.on_response);

      // Form container
      table = new FixedTable (4, 3);
      // FIXME Table.row_spacing needs [NoAccessorMethod] in the VAPI, in
      // Vala 0.7.6
      //table.row_spacing = 5;
      table.set_row_spacings (5);
      table.column_spacing = 5;

      // Icon
      if (this._entry.key_exists ("Icon"))
      {
        icon = this._entry.icon;
      }
      else
      {
        icon = STOCK_MISSING_IMAGE;
      }
      this._icon = new IconButton (icon);
      this._icon.icon_selected.connect (this.on_icon_changed);
      table.attach_defaults (this._icon, 0, 1, 0, 3);

      // Name
      name_label = new Label.with_mnemonic (_ ("_Name:"));
      table.attach_defaults (name_label, 1, 2, 0, 1);
      this._name = new Entry ();
      name_label.set_mnemonic_widget (this._name);
      if (this._entry.key_exists ("Name"))
      {
        this._name.set_text (this._entry.name);
      }
      this._name.changed.connect (this.on_name_changed);
      table.attach_defaults (this._name, 2, 3, 0, 1);

      // Description
      desc_label = new Label.with_mnemonic (_ ("_Description:"));
      table.attach_defaults (desc_label, 1, 2, 1, 2);
      this._desc = new Entry ();
      desc_label.set_mnemonic_widget (this._desc);
      if (this._entry.key_exists ("Comment"))
      {
        this._desc.set_text (this._entry.get_string ("Comment"));
      }
      this._desc.changed.connect (this.on_desc_changed);
      table.attach_defaults (this._desc, 2, 3, 1, 2);

      // Exec
      exec_label = new Label.with_mnemonic (_ ("_Command:"));
      table.attach_defaults (exec_label, 1, 2, 2, 3);
      exec_hbox = new HBox (false, 5);
      this._exec = new Entry ();
      exec_label.set_mnemonic_widget (this._exec);
      if (this._entry.key_exists ("Exec"))
      {
        this._exec.set_text (this._entry.get_string ("Exec"));
      }
      this._exec.changed.connect (this.on_exec_changed);
      exec_hbox.add (this._exec);
      exec_button = new Button.with_mnemonic (_ ("_Browse..."));
      exec_image = new Image.from_stock (STOCK_OPEN, IconSize.BUTTON);
      exec_button.set_image (exec_image);
      exec_button.clicked.connect (this.on_exec_browse);
      exec_hbox.add (exec_button);
      table.attach_defaults (exec_hbox, 2, 3, 2, 3);

      // Advanced options
      // TODO look into ResizeMode so that the window shrinks when the expander
      // is un-expanded.
      advanced = new Expander.with_mnemonic (_ ("_Advanced"));
      advanced_vbox = new VBox (false, 5);
      this._terminal = new CheckButton.with_mnemonic (_ ("Run in _terminal"));
      if (this._entry.key_exists ("Terminal"))
      {
        this._terminal.active = this._entry.get_boolean ("Terminal");
      }
      this._terminal.toggled.connect (this.on_terminal_toggled);
      advanced_vbox.add (this._terminal);
      this._startup_notification = new CheckButton.with_mnemonic (_ ("Use _startup notification"));
      if (this._entry.key_exists ("StartupNotify"))
      {
        this._startup_notification.active = this._entry.get_boolean ("StartupNotify");
      }
      this._startup_notification.toggled.connect (this.on_startup_notification_toggled);
      advanced_vbox.add (this._startup_notification);
      advanced.add (advanced_vbox);
      table.attach_fill (advanced, 0, 3, 3, 4);

      List<unowned Widget> focus_chain_list = new List<unowned Widget> ();
      focus_chain_list.append (this._name);
      focus_chain_list.append (this._desc);
      focus_chain_list.append (exec_hbox);
      focus_chain_list.append (this._icon);
      focus_chain_list.append (advanced);
      table.set_focus_chain (focus_chain_list);

      this.vbox.add (table);
    }

    private void
    on_icon_changed (IconButton button)
    {
      this._entry.icon = button.icon;
    }

    private void
    on_name_changed (Editable editable)
    {
      Entry entry = editable as Entry;
      this._entry.name = entry.text;
    }

    private void
    on_desc_changed (Editable editable)
    {
      Entry entry = editable as Entry;
      this._entry.set_string ("Comment", entry.text);
    }

    private void
    on_exec_changed (Editable editable)
    {
      Entry entry = editable as Entry;
      this._entry.set_string ("Exec", entry.text);
    }

    private void
    on_exec_browse (Button btn)
    {
      FileChooserDialog dialog;
      int response;

      dialog = new FileChooserDialog (_ ("Locate Command"), this,
                                      FileChooserAction.OPEN,
                                      STOCK_CANCEL, ResponseType.CANCEL,
                                      STOCK_OK, ResponseType.OK);
      response = dialog.run ();
      if (response == ResponseType.OK)
      {
        this._exec.text = dialog.get_filename ();
      }
      dialog.destroy ();
    }

    private void
    on_terminal_toggled (ToggleButton button)
    {
      this._entry.set_boolean ("Terminal", button.active);
    }

    private void
    on_startup_notification_toggled (ToggleButton button)
    {
      this._entry.set_boolean ("StartupNotify", button.active);
    }

    /**
     * Pops up a "Save As" dialog.
     */
    private bool
    change_output_file_prompt ()
    {
      FileChooserDialog dialog;
      int response;
      bool try_to_save;

      dialog = new FileChooserDialog (_ ("Save As"), this,
                                      FileChooserAction.SAVE,
                                      STOCK_CANCEL, ResponseType.CANCEL,
                                      STOCK_SAVE_AS, ResponseType.ACCEPT);
      response = dialog.run ();
      if (response == ResponseType.ACCEPT)
      {
        this._output = VFS.file_new_for_uri (dialog.get_uri ());
        try_to_save = true;
      }
      else
      {
        try_to_save = false;
      }
      dialog.destroy ();
      return try_to_save;
    }

    private void
    on_response (int response_id)
    {
      bool try_to_save = true;

      if (response_id == ResponseType.APPLY)
      {
        if (this._output.exists ())
        {
          if (!this._output.is_writable ())
          {
            try_to_save = this.change_output_file_prompt ();
          }
        }
        else
        {
          VFS.File? directory;

          directory = this._output.parent;
          if (directory == null || !directory.is_writable ())
          {
            try_to_save = this.change_output_file_prompt ();
          }
        }
        if (try_to_save)
        {
          if (this._entry.entry_type == DesktopEntryType.UNKNOWN)
          {
            this._entry.entry_type = DesktopEntryType.APPLICATION;
          }
          try
          {
            this._entry.save (this._output);
          }
          catch (Error err)
          {
            MessageDialog dialog;

            dialog = new MessageDialog (this, DialogFlags.MODAL, MessageType.ERROR,
                                        ButtonsType.OK,
                                        _ ("An error occurred while trying to save the desktop entry:\n\n%s"),
                                        err.message);
            dialog.run ();
            dialog.destroy ();
          }
        }
      }
      if (this._standalone)
      {
        main_quit ();
      }
      else
      {
        this.hide ();
      }
    }
  }
}

// vim:et:ai:cindent:ts=2 sts=2 sw=2
