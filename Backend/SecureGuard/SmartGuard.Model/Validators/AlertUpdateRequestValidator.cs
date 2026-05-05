using FluentValidation;
using SmartGuard.Model.Requests;

namespace SmartGuard.Model.Validators
{
    public class AlertUpdateRequestValidator : AbstractValidator<AlertUpdateRequest>
    {
        public AlertUpdateRequestValidator()
        {
            RuleFor(x => x.DismissalReason)
                .NotEmpty()
                .When(x => x.StatusId == 3) // 3 is Dismissed
                .WithMessage("Dismissal reason is mandatory when dismissing an alert");
        }
    }
}
