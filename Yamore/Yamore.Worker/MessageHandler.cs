using System.Globalization;
using System.Net;
using System.Net.Mail;
using System.Text;
using System.Text.Json;
using System.Text.RegularExpressions;
using Yamore.Model.Messages;

namespace Yamore.Worker;

/// <summary>
/// Processes messages from RabbitMQ: logging and optional email (when SMTP is configured).
/// SMTP and RabbitMQ credentials come from environment variables (e.g. Smtp__Host, RabbitMQ__UserName)
/// or other configuration providers — not from committed appsettings.
/// </summary>
public class MessageHandler
{
    private static readonly Regex _simpleEmailRegex =
        new(@"^[^@\s]+@[^@\s]+\.[^@\s]+$", RegexOptions.Compiled | RegexOptions.IgnoreCase);

    private static readonly CultureInfo _emailCulture = CultureInfo.GetCultureInfo("en-GB");

    private readonly ILogger<MessageHandler> _logger;
    private readonly IConfiguration _configuration;

    public MessageHandler(ILogger<MessageHandler> logger, IConfiguration configuration)
    {
        _logger = logger;
        _configuration = configuration;
    }

    public async Task HandleAsync(string messageType, string payloadJson)
    {
        _logger.LogInformation("Processing message type: {MessageType}", messageType);

        switch (messageType)
        {
            case MessageEnvelope.ReservationCreated:
                await HandleReservationCreatedAsync(payloadJson);
                break;
            case MessageEnvelope.PaymentCompleted:
                await HandlePaymentCompletedAsync(payloadJson);
                break;
            case MessageEnvelope.ReviewSubmitted:
                await HandleReviewSubmittedAsync(payloadJson);
                break;
            default:
                _logger.LogWarning("Unknown message type: {MessageType}", messageType);
                break;
        }
    }

    private async Task HandleReservationCreatedAsync(string payloadJson)
    {
        var msg = JsonSerializer.Deserialize<ReservationCreatedMessage>(payloadJson);
        if (msg == null) return;

        _logger.LogInformation(
            "Reservation created: Id={ReservationId}, UserId={UserId}, YachtId={YachtId}, Start={StartDate}, End={EndDate}, TotalPrice={TotalPrice}",
            msg.ReservationId, msg.UserId, msg.YachtId, msg.StartDate, msg.EndDate, msg.TotalPrice);

        if (!_isValidEmail(msg.UserEmail))
        {
            _logger.LogWarning(
                "ReservationCreated email skipped: invalid or missing recipient for ReservationId={ReservationId}, UserId={UserId}, Email={Email}",
                msg.ReservationId, msg.UserId, msg.UserEmail ?? "(null)");
            return;
        }

        var yachtLine = !string.IsNullOrWhiteSpace(msg.YachtName)
            ? msg.YachtName.Trim()
            : $"Yacht (ID {msg.YachtId})";
        var period = FormatDateRange(msg.StartDate, msg.EndDate);
        var greet = GreetingName(msg.UserName);
        var totalLine = msg.TotalPrice.HasValue
            ? $"Total: EUR {msg.TotalPrice.Value:N2}"
            : null;

        var body = new StringBuilder();
        body.AppendLine(greet);
        body.AppendLine();
        body.AppendLine("Thank you for choosing Yamore. We have received your booking with the following details:");
        body.AppendLine();
        body.AppendLine($"Yacht: {yachtLine}");
        body.AppendLine($"Charter period: {period}");
        body.AppendLine($"Reference: #{msg.ReservationId}");
        if (totalLine != null)
            body.AppendLine(totalLine);
        body.AppendLine();
        body.AppendLine("We will process your request and contact you if any further information is required.");
        body.AppendLine();
        body.AppendLine("Kind regards,");
        body.AppendLine("Yamore");

        var subject = $"Booking received - {yachtLine} ({period})";

        await SendEmailAsync(msg.UserEmail!, subject, body.ToString());
    }

    private async Task HandlePaymentCompletedAsync(string payloadJson)
    {
        var msg = JsonSerializer.Deserialize<PaymentCompletedMessage>(payloadJson);
        if (msg == null) return;

        _logger.LogInformation(
            "Payment completed: PaymentId={PaymentId}, ReservationId={ReservationId}, Amount={Amount}, Method={Method}",
            msg.PaymentId, msg.ReservationId, msg.Amount, msg.PaymentMethod);

        if (!_isValidEmail(msg.UserEmail))
        {
            _logger.LogWarning(
                "PaymentCompleted email skipped: invalid or missing recipient for ReservationId={ReservationId}, PaymentId={PaymentId}, Email={Email}",
                msg.ReservationId, msg.PaymentId, msg.UserEmail ?? "(null)");
            return;
        }

        var yachtLine = !string.IsNullOrWhiteSpace(msg.YachtName)
            ? msg.YachtName.Trim()
            : $"Yacht (ID from reservation #{msg.ReservationId})";
        var period = msg.ReservationStartDate.HasValue && msg.ReservationEndDate.HasValue
            ? FormatDateRange(msg.ReservationStartDate.Value, msg.ReservationEndDate.Value)
            : null;
        var greet = GreetingName(msg.UserName);

        var body = new StringBuilder();
        body.AppendLine(greet);
        body.AppendLine();
        if (msg.IsConfirmed)
        {
            body.AppendLine("We have successfully recorded your payment. Please find the details below:");
        }
        else
        {
            body.AppendLine("We have recorded your payment arrangement. Please find the details below:");
        }
        body.AppendLine();
        body.AppendLine($"Yacht: {yachtLine}");
        if (period != null)
            body.AppendLine($"Charter period: {period}");
        body.AppendLine($"Reservation reference: #{msg.ReservationId}");
        body.AppendLine($"Amount: EUR {msg.Amount:N2}");
        body.AppendLine($"Payment method: {msg.PaymentMethod ?? "—"}");
        if (!string.IsNullOrWhiteSpace(msg.PaymentStatus) && !msg.IsConfirmed)
            body.AppendLine($"Status: {msg.PaymentStatus}");
        body.AppendLine();
        body.AppendLine("If you have any questions, please contact us and quote your reservation reference.");
        body.AppendLine();
        body.AppendLine("Kind regards,");
        body.AppendLine("Yamore");

        var subject = msg.IsConfirmed
            ? (period != null
                ? $"Payment received - {yachtLine} ({period})"
                : $"Payment received - {yachtLine} (ref. #{msg.ReservationId})")
            : (period != null
                ? $"Payment update - {yachtLine} ({period})"
                : $"Payment update - {yachtLine} (ref. #{msg.ReservationId})");

        await SendEmailAsync(msg.UserEmail!, subject, body.ToString());
    }

    private Task HandleReviewSubmittedAsync(string payloadJson)
    {
        var msg = JsonSerializer.Deserialize<ReviewSubmittedMessage>(payloadJson);
        if (msg == null) return Task.CompletedTask;

        _logger.LogInformation(
            "Review submitted: ReviewId={ReviewId}, YachtId={YachtId}, UserId={UserId}, Rating={Rating}",
            msg.ReviewId, msg.YachtId, msg.UserId, msg.Rating);

        return Task.CompletedTask;
    }

    private async Task SendEmailAsync(string to, string subject, string body)
    {
        var host = _configuration["Smtp:Host"];
        if (string.IsNullOrWhiteSpace(host))
        {
            _logger.LogDebug("Smtp:Host not configured. Skipping email to {To}", to);
            return;
        }

        var portStr = _configuration["Smtp:Port"];
        var port = 587;
        if (!string.IsNullOrWhiteSpace(portStr) && int.TryParse(portStr, out var p))
            port = p;

        var userName = _configuration["Smtp:UserName"];
        var password = _configuration["Smtp:Password"];
        var useSsl = _configuration.GetValue("Smtp:UseSsl", true);
        var from = _configuration["Smtp:FromAddress"] ?? "noreply@yamore.example";
        var fromName = _configuration["Smtp:FromDisplayName"] ?? "Yamore";

        if (string.IsNullOrWhiteSpace(userName) || string.IsNullOrWhiteSpace(password))
        {
            _logger.LogWarning(
                "Smtp:Host is set but Smtp:UserName or Smtp:Password is empty. Most providers (Gmail, Outlook) require both. Skipping email to {To}",
                to);
            return;
        }

        using var client = new SmtpClient(host, port);
        // Required for explicit mailbox login; otherwise some servers return 5.7.0 Authentication Required.
        client.UseDefaultCredentials = false;
        client.EnableSsl = useSsl;
        client.Credentials = new NetworkCredential(userName, password);

        var mail = new MailMessage(from, to, subject, body) { IsBodyHtml = false };
        mail.From = new MailAddress(from, fromName);

        await client.SendMailAsync(mail);
        _logger.LogInformation("Email sent to {To}, subject: {Subject}", to, subject);
    }

    private static bool _isValidEmail(string? email)
    {
        if (string.IsNullOrWhiteSpace(email))
            return false;
        return _simpleEmailRegex.IsMatch(email.Trim());
    }

    private static string GreetingName(string? fullName) =>
        !string.IsNullOrWhiteSpace(fullName) ? $"Dear {fullName.Trim()}," : "Dear customer,";

    private static string FormatDateRange(DateTime start, DateTime end) =>
        $"{start.ToString("dd MMMM yyyy", _emailCulture)} - {end.ToString("dd MMMM yyyy", _emailCulture)}";
}
