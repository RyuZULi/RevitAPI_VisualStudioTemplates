#if (addinLogging && diContainer)
using Serilog;

#endif
#if (addinLogging && diHosting)
using Microsoft.Extensions.Logging;

#endif
namespace Nice3point.Revit.AddIn._1.ViewModels;

#if (!addinLogging)
public sealed class Nice3point_Revit_AddIn__1ViewModel : ObservableObject
#elseif (diContainer)
public sealed class Nice3point_Revit_AddIn__1ViewModel(ILogger logger) : ObservableObject
#elseif (diHosting)
public sealed class Nice3point_Revit_AddIn__1ViewModel(ILogger<Nice3point_Revit_AddIn__1ViewModel> logger) : ObservableObject
#else
public sealed class Nice3point_Revit_AddIn__1ViewModel : ObservableObject
#endif
{
}