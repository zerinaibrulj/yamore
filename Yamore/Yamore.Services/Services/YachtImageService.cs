using System;
using System.Collections.Generic;
using System.Linq;
using Yamore.Model;
using Yamore.Model.Requests.YachtImage;
using Yamore.Services.Database;
using Yamore.Services.Interfaces;

namespace Yamore.Services.Services
{
    public class YachtImageService : IYachtImageService
    {
        private readonly _220245Context _context;

        public YachtImageService(_220245Context context)
        {
            _context = context;
        }

        public PagedResponse<Model.YachtImage> GetByYachtIdPaged(int yachtId, int page, int pageSize)
        {
            page = PagingConstraints.NormalizePage(page);
            pageSize = PagingConstraints.NormalizePageSize(pageSize);

            var q = _context.YachtImages
                .Where(i => i.YachtId == yachtId)
                .OrderBy(i => i.SortOrder)
                .ThenBy(i => i.DateAdded);

            var count = q.Count();
            var list = q.Skip(page * pageSize).Take(pageSize)
                .Select(i => new Model.YachtImage
                {
                    YachtImageId = i.YachtImageId,
                    YachtId = i.YachtId,
                    ContentType = i.ContentType,
                    FileName = i.FileName,
                    IsThumbnail = i.IsThumbnail,
                    SortOrder = i.SortOrder,
                    DateAdded = i.DateAdded,
                })
                .ToList();

            return new PagedResponse<Model.YachtImage>
            {
                Count = count,
                ResultList = list,
            };
        }

        public Database.YachtImage? GetRawById(int imageId)
        {
            return _context.YachtImages.Find(imageId);
        }

        public Model.YachtImage Upload(int yachtId, YachtImageInsertRequest request)
        {
            byte[] imageData;
            try
            {
                imageData = Convert.FromBase64String(request.ImageDataBase64);
            }
            catch (FormatException)
            {
                throw new UserException("Image data is not valid Base64. Please re-upload the image.");
            }

            var isFirst = !_context.YachtImages.Any(i => i.YachtId == yachtId);
            var nextSort = isFirst
                ? 0
                : _context.YachtImages
                    .Where(i => i.YachtId == yachtId)
                    .Max(i => i.SortOrder) + 1;

            var entity = new Database.YachtImage
            {
                YachtId = yachtId,
                ImageData = imageData,
                ContentType = request.ContentType,
                FileName = request.FileName,
                IsThumbnail = isFirst,
                SortOrder = nextSort,
                DateAdded = DateTime.UtcNow,
            };

            _context.YachtImages.Add(entity);
            _context.SaveChanges();

            return new Model.YachtImage
            {
                YachtImageId = entity.YachtImageId,
                YachtId = entity.YachtId,
                ContentType = entity.ContentType,
                FileName = entity.FileName,
                IsThumbnail = entity.IsThumbnail,
                SortOrder = entity.SortOrder,
                DateAdded = entity.DateAdded,
            };
        }

        public void Delete(int imageId)
        {
            var entity = _context.YachtImages.Find(imageId);
            if (entity == null) return;

            var wasThumbnail = entity.IsThumbnail;
            var yachtId = entity.YachtId;

            _context.YachtImages.Remove(entity);
            _context.SaveChanges();

            if (wasThumbnail)
            {
                var next = _context.YachtImages
                    .Where(i => i.YachtId == yachtId)
                    .OrderBy(i => i.SortOrder)
                    .FirstOrDefault();
                if (next != null)
                {
                    next.IsThumbnail = true;
                    _context.SaveChanges();
                }
            }
        }

        public void SetThumbnail(int imageId)
        {
            var entity = _context.YachtImages.Find(imageId);
            if (entity == null) return;

            var current = _context.YachtImages
                .Where(i => i.YachtId == entity.YachtId && i.IsThumbnail)
                .ToList();

            foreach (var img in current)
                img.IsThumbnail = false;

            entity.IsThumbnail = true;
            _context.SaveChanges();
        }
    }
}
