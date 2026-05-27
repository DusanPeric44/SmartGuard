using System.Text.Json;
using System.Text.Json.Serialization;

namespace SmartGuard.Model.Serialization
{
    public class NumericByteArrayJsonConverter : JsonConverter<byte[]>
    {
        public override byte[] Read(ref Utf8JsonReader reader, Type typeToConvert, JsonSerializerOptions options)
        {
            if (reader.TokenType == JsonTokenType.String)
            {
                var base64 = reader.GetString();
                return string.IsNullOrWhiteSpace(base64) ? Array.Empty<byte>() : Convert.FromBase64String(base64);
            }

            if (reader.TokenType != JsonTokenType.StartArray)
            {
                throw new JsonException("Expected base64 string or numeric array for byte[].");
            }

            var bytes = new List<byte>();
            while (reader.Read())
            {
                if (reader.TokenType == JsonTokenType.EndArray)
                {
                    return bytes.ToArray();
                }

                if (reader.TokenType != JsonTokenType.Number)
                {
                    throw new JsonException("Expected number elements in imageBytes array.");
                }

                if (!reader.TryGetInt32(out var value) || value < byte.MinValue || value > byte.MaxValue)
                {
                    throw new JsonException("imageBytes elements must be in range 0..255.");
                }

                bytes.Add((byte)value);
            }

            throw new JsonException("Unexpected end of JSON while reading imageBytes.");
        }

        public override void Write(Utf8JsonWriter writer, byte[] value, JsonSerializerOptions options)
        {
            writer.WriteBase64StringValue(value);
        }
    }
}
