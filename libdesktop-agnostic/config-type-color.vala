
using DesktopAgnostic;

namespace DesktopAgnostic.Config
{
  public class ColorType : SchemaType
  {
    const string DEFAULT_KEY = "default";
    public override string name
    {
      get
      {
        return "color";
      }
    }
    public override Type schema_type
    {
      get
      {
        return typeof (Color);
      }
    }
    public override string
    serialize (Value val)
    {
      weak Color color = (Color)val.get_object ();
      return color.to_string ();
    }
    public override Value
    deserialize (string serialized)
    {
      Value val = Value (this.schema_type);
      Color color = Color.from_string (serialized);
      val.take_object ((Object)color);
      return val;
    }
    public override Value
    parse_default_value (KeyFile schema, string group)
    {
      return this.deserialize (schema.get_string (group, DEFAULT_KEY));
    }
    public override ValueArray
    parse_default_list_value (KeyFile schema, string group)
    {
      ValueArray array;
      string[] list = schema.get_string_list (group, DEFAULT_KEY);
      array = new ValueArray (list.length);
      foreach (weak string item in list)
      {
        array.append (this.deserialize (item));
      }
      return array;
    }
  }
}

// vim: set et ts=2 sts=2 sw=2 ai :
