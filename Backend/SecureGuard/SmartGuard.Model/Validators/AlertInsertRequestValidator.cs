using FluentValidation;
using SmartGuard.Model.Requests;

namespace SmartGuard.Model.Validators
{
    public class AlertInsertRequestValidator : AbstractValidator<AlertInsertRequest>
    {
        public AlertInsertRequestValidator()
        {
            RuleFor(x => x.TypeId).NotEmpty();
            RuleFor(x => x.DeviceId).NotEmpty();
            RuleFor(x => x.Description).NotEmpty().MaximumLength(500);
        }
    }
}
