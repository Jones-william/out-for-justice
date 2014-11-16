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
    $('.ui.checkbox').checkbox();
    $('.ui.star.rating')
      .rating('enable')
      .rating('set rating', 3);
    //$('.enable.button').on('click', function());

    // defaults here because I have no idea what I'm doing
    $("#dowdropdown").dropdown('set value', 'friday');
    $("#toddropdown").dropdown('set value', 'evening');

    // Ta I know this isn't what you wanted but it should work for now.
    $("#predict").click(function() {
      var qs = {
        dow: $("#dowdropdown").dropdown('get value'),
        tod: $("#toddropdown").dropdown('get value')
      }
      var url = HEATMAP_API + '?' + $.param(qs);
      d3.json(url, function(error, json){
	  // does this replace the global???
	  data = json.geometries;
	  renderPoints(data, layers.heatmap, 'point');
      });
    });

    $("#getcars").click(function() {
      var num_cars = parseInt($("#numcars").val());
      var json = {
	  num_cars: num_cars,
      };

      $.ajax({
         url: "/api/loss",
         contentType: "application/json",
         type: "POST",
         data: JSON.stringify(json),
         dataType: "json",
	 success: function(resp) {
           var newcars = []
           for (var i = 0; i < resp.positions.length; i++) {
             newcars.push(data[resp.positions[i]].coordinates);
           }
	   renderCars(newcars);
	 }
      });
    });

    $("#evaluate").click(function() {

    });
  })
;

expandMap();
$(window).resize(expandMap);

// Init map
var map = L.map('map', {
  center: [37.788975, -122.403452],
  zoom: 14,
  minZoom: 12,
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

  map.on('viewreset', update);
  map.on('resize', update);
  map.on('moveend', alignSVG);

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
  target.selectAll('.' + classStr).remove();

  var points = target.selectAll('.' + classStr)
    .data(dat.map(function(d) {
      return map.latLngToLayerPoint([d.coordinates[0], d.coordinates[1]]);
    }));

  points.enter().append('circle')
    .attr('class', classStr)
    .attr('r', map.getZoom() / 3.0)
    .attr('cx', function(d) { return d.x; })
    .attr('cy', function(d) { return d.y; });
}

function renderCars(dat) {
  layers.pin.selectAll('.gCar').remove();

  var groups = layers.pin.selectAll('.gCar')
    .data(dat.map(function(d) {
      return map.latLngToLayerPoint([d[0], d[1]]);
    }));

  groups.enter().append('g')
    .attr('class', 'gCar')
    .each(renderCarIcon);
}

function renderCarIcon(e) {
  var g = d3.select(this);
  g.selectAll('*').remove();

  g.attr('transform',
    'translate(' +  e.x + ',' + e.y + ')');

  g.append('circle')
    .attr('r', 28)
    .style('fill', '#564F8A')
    .style('fill-opacity', 0.5);

  g.append('circle')
    .attr('r', 24)
    .style('fill', '#564F8A');

  g.append('svg:image')
    .attr('x',-16)
    .attr('y',-16)
    .attr('width', 32)
    .attr('height', 32)
    .attr('xlink:href','/img/police.png');
}

function update() {
  renderPoints(data, layers.heatmap, 'point');
  renderCars(cars);
}

function predict() {
  var form = $('#form-predict');

}

function evaluate() {

}

function reset() {

}

function step() {

}

/* TEMP */

var data;
var cars = [[37.776317,-122.395569], [37.7483385,-122.4079037]];

d3.json(HEATMAP_API, function(error, json){
  data = json.geometries;
  var latExtent = d3.extent(data, function(d) { return d.coordinates[0]; });
  var lonExtent = d3.extent(data, function(d) { return d.coordinates[1]; });

  init();
  renderPoints(data, layers.heatmap, 'point');
  renderCars(cars);
});

