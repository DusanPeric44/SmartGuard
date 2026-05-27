namespace SmartGuard.Model
{
    public static class VectorPacking
    {
        public static byte[] PackFloat32(float[] vector)
        {
            var bytes = new byte[vector.Length * sizeof(float)];
            Buffer.BlockCopy(vector, 0, bytes, 0, bytes.Length);
            return bytes;
        }

        public static float[] UnpackFloat32(byte[] bytes)
        {
            if (bytes.Length % sizeof(float) != 0)
            {
                throw new ArgumentException("Byte array length must be a multiple of 4.");
            }

            var vector = new float[bytes.Length / sizeof(float)];
            Buffer.BlockCopy(bytes, 0, vector, 0, bytes.Length);
            return vector;
        }
    }
}
