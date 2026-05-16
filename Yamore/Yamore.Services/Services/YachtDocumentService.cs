using System;
using System.Collections.Generic;
using System.Linq;
using Microsoft.EntityFrameworkCore;
using Yamore.Model;
using Yamore.Model.Requests.YachtDocument;
using Yamore.Services.Database;
using Yamore.Services.Interfaces;

namespace Yamore.Services.Services
{
    public class YachtDocumentService : IYachtDocumentService
    {
        private readonly _220245Context _context;

        public YachtDocumentService(_220245Context context)
        {
            _context = context;
        }

        public IReadOnlyList<Model.YachtDocument> GetByYachtId(int yachtId) =>
            _context.YachtDocuments.AsNoTracking()
                .Where(d => d.YachtId == yachtId)
                .OrderBy(d => d.DocumentType)
                .ThenByDescending(d => d.DateUploaded)
                .Select(MapToModel)
                .ToList();

        public IReadOnlyList<Model.YachtDocument> GetPendingForAdmin() =>
            _context.YachtDocuments.AsNoTracking()
                .Where(d => d.VerificationStatus == YachtDocumentVerificationStatus.Pending)
                .OrderBy(d => d.YachtId)
                .ThenBy(d => d.DocumentType)
                .Select(d => new Model.YachtDocument
                {
                    YachtDocumentId = d.YachtDocumentId,
                    YachtId = d.YachtId,
                    YachtName = d.Yacht.Name,
                    DocumentType = d.DocumentType,
                    VerificationStatus = d.VerificationStatus,
                    ContentType = d.ContentType,
                    FileName = d.FileName,
                    DateUploaded = d.DateUploaded,
                    RejectionReason = d.RejectionReason,
                })
                .ToList();

        public Model.YachtDocument Upload(int yachtId, int ownerUserId, YachtDocumentInsertRequest request)
        {
            var yacht = _context.Yachts.AsNoTracking().FirstOrDefault(y => y.YachtId == yachtId);
            if (yacht == null)
                throw new NotFoundException($"Yacht with id {yachtId} not found.");
            if (yacht.OwnerId != ownerUserId)
                throw new ForbiddenException("You may only upload documents for yachts that you own.");

            var docType = YachtDocumentTypes.TryResolveMandatoryType(request.DocumentType);
            if (docType == null)
            {
                throw new UserException(
                    $"Document type must be one of: {string.Join(", ", YachtDocumentTypes.MandatoryForActivation)}.");
            }

            byte[] fileContent;
            try
            {
                fileContent = Convert.FromBase64String(request.FileDataBase64);
            }
            catch (FormatException)
            {
                throw new UserException("File data is not valid Base64.");
            }

            if (fileContent.Length == 0)
                throw new UserException("The uploaded file is empty.");

            if (fileContent.Length > 10 * 1024 * 1024)
                throw new UserException("Document file must be 10 MB or smaller.");

            var entity = new Database.YachtDocument
            {
                YachtId = yachtId,
                DocumentType = docType,
                VerificationStatus = YachtDocumentVerificationStatus.Pending,
                FileContent = fileContent,
                ContentType = string.IsNullOrWhiteSpace(request.ContentType) ? "application/octet-stream" : request.ContentType.Trim(),
                FileName = request.FileName?.Trim(),
                DateUploaded = DateTime.UtcNow,
                RejectionReason = null,
            };

            var existing = _context.YachtDocuments
                .Where(d => d.YachtId == yachtId)
                .ToList()
                .Where(d => string.Equals(d.DocumentType, docType, StringComparison.OrdinalIgnoreCase))
                .ToList();
            if (existing.Count > 0)
                _context.YachtDocuments.RemoveRange(existing);

            _context.YachtDocuments.Add(entity);
            _context.SaveChanges();
            return MapToModel(entity);
        }

        public Model.YachtDocument Verify(int documentId, int adminUserId, YachtDocumentVerifyRequest request)
        {
            var entity = _context.YachtDocuments.FirstOrDefault(d => d.YachtDocumentId == documentId);
            if (entity == null)
                throw new NotFoundException($"Document with id {documentId} not found.");

            var status = (request.VerificationStatus ?? string.Empty).Trim();
            if (string.Equals(status, YachtDocumentVerificationStatus.Approved, StringComparison.OrdinalIgnoreCase))
            {
                entity.VerificationStatus = YachtDocumentVerificationStatus.Approved;
                entity.RejectionReason = null;
            }
            else if (string.Equals(status, YachtDocumentVerificationStatus.Rejected, StringComparison.OrdinalIgnoreCase))
            {
                if (string.IsNullOrWhiteSpace(request.RejectionReason))
                    throw new UserException("A rejection reason is required when rejecting a document.");
                entity.VerificationStatus = YachtDocumentVerificationStatus.Rejected;
                entity.RejectionReason = request.RejectionReason.Trim();
                if (entity.RejectionReason.Length > 500)
                    entity.RejectionReason = entity.RejectionReason[..500];
            }
            else
            {
                throw new UserException("Verification status must be Approved or Rejected.");
            }

            _context.SaveChanges();
            return MapToModel(entity);
        }

        public byte[]? GetFileContent(int documentId) =>
            _context.YachtDocuments.AsNoTracking()
                .Where(d => d.YachtDocumentId == documentId)
                .Select(d => d.FileContent)
                .FirstOrDefault();

        public bool AreMandatoryDocumentsApproved(int yachtId)
        {
            var documents = _context.YachtDocuments.AsNoTracking()
                .Where(d => d.YachtId == yachtId)
                .Select(d => new { d.DocumentType, d.VerificationStatus })
                .ToList();

            foreach (var mandatory in YachtDocumentTypes.MandatoryForActivation)
            {
                var hasApproved = documents.Any(d =>
                    string.Equals(d.DocumentType, mandatory, StringComparison.OrdinalIgnoreCase)
                    && string.Equals(
                        d.VerificationStatus,
                        YachtDocumentVerificationStatus.Approved,
                        StringComparison.OrdinalIgnoreCase));

                if (!hasApproved)
                    return false;
            }

            return true;
        }

        public Database.YachtDocument? GetEntity(int documentId) =>
            _context.YachtDocuments.Find(documentId);

        private static Model.YachtDocument MapToModel(Database.YachtDocument d) => new()
        {
            YachtDocumentId = d.YachtDocumentId,
            YachtId = d.YachtId,
            DocumentType = d.DocumentType,
            VerificationStatus = d.VerificationStatus,
            ContentType = d.ContentType,
            FileName = d.FileName,
            DateUploaded = d.DateUploaded,
            RejectionReason = d.RejectionReason,
        };
    }
}
