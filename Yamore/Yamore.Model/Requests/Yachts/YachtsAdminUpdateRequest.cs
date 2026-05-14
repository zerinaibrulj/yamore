namespace Yamore.Model.Requests.Yachts
{
    /// <summary>
    /// Admin-only yacht update, including reassignment of <see cref="OwnerId"/>.
    /// </summary>
    public class YachtsAdminUpdateRequest : YachtsUpdateRequest
    {
        public int OwnerId { get; set; }
    }
}
