namespace SmartGuard.Model.Interfaces
{
    public interface ICosineSimilarityService
    {
        double CalculateSimilarity(float[] vector1, float[] vector2);
        bool IsMatch(float[] vector1, float[] vector2, double threshold = 0.75);
    }
}
