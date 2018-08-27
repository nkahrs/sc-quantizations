(
// create window
w = Window.new("Quantizations 3", Rect(0, 0, 600, 400));
// create number box
n = NumberBox(w, Rect(50, 50, 500, 300));
n.font = Font("Arial", 250);
// action: just post the current number (this might change)
n.action = {arg foo; ~cues[foo.value].value;}; //foo.value.postln;};
// set initial value to zero
n.value_(0);
// when pressing spacebar (and only spacebar!), increment
n.keyDownAction_({arg i,j; if (j.asString==" ") {n.value_(n.value + 1); n.action.value(n)}});
// push window to the front.
w.front;
)