namespace Yamore.Model.Requests.Yachts
{
    /// <summary>
    /// Admin-only yacht creation: assigns <see cref="OwnerId"/> explicitly.
    /// Use <c>POST /Yachts/admin</c> with an Admin token — not the owner-facing <c>POST /Yachts</c>.
    /// </summary>
    public class YachtsAdminInsertRequest : YachtsInsertRequest
    {
        public int OwnerId { get; set; }
    }
}
