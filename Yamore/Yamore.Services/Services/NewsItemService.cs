using System;
using System.Linq;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;
using Yamore.Model;
using Yamore.Model.Requests.News;
using Yamore.Model.SearchObjects;
using Yamore.Services.Database;
using Yamore.Services.Interfaces;
using NewsEntity = Yamore.Services.Database.NewsItem;

namespace Yamore.Services.Services
{
    public class NewsItemService
        : BaseCRUDService<Model.NewsItem, NewsItemSearchObject, NewsEntity, NewsItemInsertRequest, NewsItemUpdateRequest, NewsItemDeleteRequest>,
            INewsItemService
    {
        public NewsItemService(_220245Context context, IMapper mapper)
            : base(context, mapper)
        {
        }

        public override PagedResponse<Model.NewsItem> GetPaged(NewsItemSearchObject search)
        {
            search ??= new NewsItemSearchObject();
            search.Page = PagingConstraints.NormalizePage(search.Page);
            search.PageSize = PagingConstraints.NormalizePageSize(search.PageSize);

            var query = Context.Set<NewsEntity>().AsQueryable();
            query = AddFilter(search, query);
            query = query.OrderByDescending(x => x.CreatedAt);
            int count = query.Count();
            var list = query
                .Skip(search.Page!.Value * search.PageSize!.Value)
                .Take(search.PageSize.Value)
                .ToList();
            var result = list.Select(x => Mapper.Map<Model.NewsItem>(x)).ToList();
            return new PagedResponse<Model.NewsItem> { Count = count, ResultList = result };
        }

        public override IQueryable<NewsEntity> AddFilter(NewsItemSearchObject search, IQueryable<NewsEntity> query)
        {
            var q = base.AddFilter(search, query);
            if (!string.IsNullOrWhiteSpace(search?.TitleContains))
            {
                var t = search!.TitleContains!.Trim();
                q = q.Where(x => x.Title.Contains(t));
            }
            if (!string.IsNullOrWhiteSpace(search?.TextContains))
            {
                var t = search!.TextContains!.Trim();
                q = q.Where(x => x.Text.Contains(t));
            }
            if (search?.CreatedFrom != null)
            {
                q = q.Where(x => x.CreatedAt >= search!.CreatedFrom!.Value);
            }
            if (search?.CreatedTo != null)
            {
                q = q.Where(x => x.CreatedAt <= search!.CreatedTo!.Value);
            }
            return q;
        }

        public override void BeforeInsret(NewsItemInsertRequest request, NewsEntity entity)
        {
            if (entity.CreatedAt == default)
                entity.CreatedAt = DateTime.UtcNow;
        }
    }
}
