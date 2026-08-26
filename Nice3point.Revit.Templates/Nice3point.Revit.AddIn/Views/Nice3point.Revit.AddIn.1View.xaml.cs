using Nice3point.Revit.AddIn._1.ViewModels;

namespace Nice3point.Revit.AddIn._1.Views;

public sealed partial class Nice3point_Revit_AddIn__1View
{
    public Nice3point_Revit_AddIn__1View(Nice3point_Revit_AddIn__1ViewModel viewModel)
    {
        DataContext = viewModel;
        InitializeComponent();
    }
}