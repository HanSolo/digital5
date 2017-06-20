using Toybox.Application as App;
using Toybox.WatchUi as Ui;

class Digital5App extends App.AppBase {

    function initialize() {
        AppBase.initialize();
    }

    // onStart() is called on application start up
    function onStart(state) {
    }

    // onStop() is called when your application is exiting
    function onStop(state) {
    }

    // Return the initial view of your application here
    function getInitialView() {
        if( Toybox.WatchUi has :WatchFaceDelegate ) {
            return [new Digital5View(), new Digital5Delegate()];
        } else {
            return [new Digital5View()];
        }
    }
    
    //! New app settings have been received so trigger a UI update
    function onSettingsChanged() {
        Ui.requestUpdate();
    }
    
    // This method runs when a goal is triggered and the goal view is started.
    //function getGoalView(goal) {
    //    return [new Digital5GoalView(goal)];
    //}
}