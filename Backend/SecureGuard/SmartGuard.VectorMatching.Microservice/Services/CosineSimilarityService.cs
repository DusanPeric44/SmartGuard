using SmartGuard.Model.Interfaces;

namespace SmartGuard.VectorMatching.Microservice.Services
{
    public class CosineSimilarityService : ICosineSimilarityService
    {
        public double CalculateSimilarity(float[] vector1, float[] vector2)
        {
            if (vector1.Length != vector2.Length)
                throw new ArgumentException("Vectors must have the same length");

            double dotProduct = 0;
            double normA = 0;
            double normB = 0;

            for (int i = 0; i < vector1.Length; i++)
            {
                dotProduct += vector1[i] * vector2[i];
                normA += Math.Pow(vector1[i], 2);
                normB += Math.Pow(vector2[i], 2);
            }

            if (normA == 0 || normB == 0) return 0;

            return dotProduct / (Math.Sqrt(normA) * Math.Sqrt(normB));
        }

        public bool IsMatch(float[] vector1, float[] vector2, double threshold = 0.75)
        {
            return CalculateSimilarity(vector1, vector2) >= threshold;
        }
    }
}
