var HEATMAP_API = 'api/heatmap.json'

function expandMap() {
  // Expand map to 100% height
  var offsetTop = $('#navbar').height();
  $('#map-column').height($(window).height() - offsetTop);
  $('#form-column').height($(window).height() - offsetTop);
}

$(document)
  .ready(function() {
    $('.ui.selection.dropdown').dropdown();
  })
;

expandMap();
$(window).resize(expandMap);

// Init map
var map = L.map('map', {
  center: [37.788975, -122.403452],
  zoom: 13,
  minZoom: 8,
  layers: new L.StamenTileLayer('toner-lite'),
  scrollWheelZoom: false,
  zoomControl: false
});

new L.Control.Zoom({ position: 'topright' }).addTo(map);

// TO-DO: Init map location
// map.panTo(
//   [landmarks[selected.landmark].lat, landmarks[selected.landmark].lon],
//   {animate: false, noMoveStart: true});

var mapOffset = $('#map').offset();

var svg;
var layers = {};

function init() {
  svg = d3.select(map.getPanes().overlayPane)
    .append('svg')
  .attr('width', map.getSize().x * 2)
  .attr('height', map.getSize().y * 2);

  layers.heatmap = svg.append('g')
    .attr('class', 'leaflet-zoom-hide');
  layers.pin = svg.append('g')
    .attr('class', 'leaflet-zoom-hide');

  alignSVG();

  // map.on('viewreset', update);
  // map.on('resize', update);
  map.on('moveend', alignSVG);
}

function render() {

}

// Align SVG layer with map tiles
function alignSVG() {
  var origin = map.getPixelOrigin();
  var topLeft = map.getPixelBounds().min;
  tileOffset = [topLeft.x - origin.x, topLeft.y - origin.y];

  var svgOffset = [tileOffset[0] - map.getSize().x / 2,
                   tileOffset[1] - map.getSize().y / 2];

  svg.attr('width', map.getSize().x * 2)
    .attr('height', map.getSize().y * 2)
    .style("margin-left", svgOffset[0])
    .style("margin-top", svgOffset[1]);

  for (var key in layers) {
    if (layers.hasOwnProperty(key)) {
      layers[key]
        .attr("transform", "translate(" + -svgOffset[0] + "," + -svgOffset[1] + ")");
    }
  }
}

function renderPoints(dat, target, classStr) {
  var points = layers.pin.selectAll(classStr)
    .data(dat);

  points.enter().append('circle')
    .attr('class', classStr)
    .attr('r', 5)
    .attr('cx', function(d) { return map.latLngToLayerPoint(d).x; } )
    .attr('cy', function(d) { return map.latLngToLayerPoint(d).x; } )
}

d3.json(HEATMAP_API, function(error, json){
  console.log(json);
  init();
  renderPoints(json.coordinates, layers.pin, '.point');
});

