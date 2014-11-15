$("#map").height($(window).height() - $("#navbar").height());

var map = L.map('map', {
  center: [37.788975, -122.403452],
  zoom: 13,
  minZoom: 8,
  layers: new L.StamenTileLayer('toner-hybrid'),
  scrollWheelZoom: false,
  zoomControl: false
});

new L.Control.Zoom({ position: 'topright' }).addTo(map);
