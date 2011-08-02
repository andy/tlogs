var blinks = $A();
function blink(element) {
  var element = $(element);

  blinks.push(element.id);
  blinker(element);
}

function blinker(element) {
  Effect.toggle(element, 'appear', { duration: 0.3, from: 1.0, to: 0.2, afterFinish: function() { if(blinks.include(element.id)) blinker(element); } });
}

function unblink(element) {
  var element = $(element);

  blinks = blinks.without(element.id);
}
