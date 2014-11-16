var HEATMAP_API = 'api/heatmap.json'
var HEATMAP_COLOR = ["#f7f4f9","#e7e1ef","#d4b9da","#c994c7","#df65b0","#e7298a","#ce1256","#980043","#67001f"];

var nodes;
var selectedType = 'violent';
var car_positions;

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

    // defaults here because I have no idea what I'm doing
    $("#dowdropdown").dropdown('set value', 'friday');
    $("#toddropdown").dropdown('set value', 'evening');

    $("#crimeType").change(function() {
      selectedType = $("#crimeType input:checked").val();
      if (nodes) {
        renderPoints(nodes, selectedType, layers.heatmap, 'point');
      }
    });

    // Ta I know this isn't what you wanted but it should work for now.
    $("#predict").click(function() {
      var qs = {
        dow: $("#dowdropdown").dropdown('get value'),
        tod: $("#toddropdown").dropdown('get value')
      }
      var url = HEATMAP_API + '?' + $.param(qs);
      d3.json(url, function(error, json){
    	  // does this replace the global???
    	  nodes = json.geometries;
        init();
    	  renderPoints(nodes, selectedType, layers.heatmap, 'point');
      });
    });

    $("#getcars").click(function() {
      var num_cars = parseInt($("#numcars").val());
      var json = {
	  num_cars: num_cars,
      };
      console.log(num_cars);
      $.ajax({
         url: "/api/loss",
         contentType: "application/json",
         type: "POST",
         data: JSON.stringify(json),
         dataType: "json",
	 success: function(resp) {
           var newcars = []
           for (var i = 0; i < resp.positions.length; i++) {
             newcars.push(nodes[resp.positions[i]].coordinates);
           }
	   renderCars(newcars);
	   car_positions = resp.positions;
	 }
      });
    });

    $("#evaluate").click(function() {
	var json = {
	    weights: [
		$("#star-intox").rating("get rating"),
		$("#star-property").rating("get rating"),
		$("#star-violent").rating("get rating"),
	    ],
	    positions: car_positions,
	    dow: $("#dowdropdown").dropdown('get value'),
            tod: $("#toddropdown").dropdown('get value')
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
             newcars.push(nodes[resp.positions[i]].coordinates);
           }
	   renderCars(newcars);

	   $('#intox-loss').text(
	       d3.round(resp.intoxication / json.weights[0], 1));
	   $('#property-loss').text(
	       d3.round(resp.property / json.weights[1], 1));
	   $('#violent-loss').text(
	       d3.round(resp.violent / json.weights[2], 1));
     $('#overall-loss').text(
         d3.round(resp.intoxication  / json.weights[0] +
          resp.property  / json.weights[1] +
          resp.violent / json.weights[2]
          , 1));

	 }
      });
    });

    $("#step").click(function() {
	var json = {
	    weights: [
		$("#star-intox").rating("get rating"),
		$("#star-property").rating("get rating"),
		$("#star-violent").rating("get rating"),
	    ],
	    positions: car_positions,
	    dow: $("#dowdropdown").dropdown('get value'),
            tod: $("#toddropdown").dropdown('get value')
	};

      $.ajax({
         url: "/api/step",
         contentType: "application/json",
         type: "POST",
         data: JSON.stringify(json),
         dataType: "json",
	 success: function(resp) {

           var newcars = []
           for (var i = 0; i < resp.positions.length; i++) {
             newcars.push(nodes[resp.positions[i]].coordinates);
           }
	   renderCars(newcars);
	   car_positions = resp.positions;

	   $('#intox-loss').text(
	       d3.round(resp.intoxication / json.weights[0], 1));
	   $('#property-loss').text(
	       d3.round(resp.property / json.weights[1], 1));
	   $('#violent-loss').text(
	       d3.round(resp.violent / json.weights[2], 1));

	 }
      });

    });
  })
;

expandMap();
$(window).resize(expandMap);

// Init map
var map = L.map('map', {
  center: [37.767254489700846, -122.439],
  zoom: 13,
  minZoom: 13,
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
  d3.select(map.getPanes().overlayPane)
    .select('svg')
    .remove();

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

function renderPoints(dat, type, target, classStr) {
  target.selectAll('.' + classStr).remove();

  var newData = dat.map(function(d) {
    var value;
    if (type === 'intox') {
      value = d.intoxication;
    } else if (type === 'property') {
      value = d.property;
    } else {
      value = d.violent;
    }

    return {
      point: map.latLngToLayerPoint([d.coordinates[0], d.coordinates[1]]),
      value: value
    };
  })

  newData = newData.filter(function(d) { return d.value > 2.5; })

  // Move this outside. Do it once, and cache it!
  var quantile = d3.scale.quantile()
    .domain(d3.extent(newData, function(d) { return d.value; }))
    .range([2, 3, 4, 5, 6, 7, 8]);
  // var color = d3.scale.log()
  //   .domain([1, 6])
  //   .range(['#6ECFF5', '#D95C5C']);

  var points = target.selectAll('.' + classStr)
    .data(newData);

  points.enter().append('circle')
    .attr('class', classStr)
    .attr('r', map.getZoom() / 3.0)
    .attr('cx', function(d) { return d.point.x; })
    .attr('cy', function(d) { return d.point.y; })
    .style('fill', function(d) { return HEATMAP_COLOR[quantile(d.value)]; })
    .style('opacity', function(d) { return quantile(d.value) < 3 ? 0.25 : 0.8; });
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
  renderPoints(nodes, selectedType, layers.heatmap, 'point');
  renderCars(cars);
}

/* TESET */

// var cars = [[37.776317,-122.395569], [37.7483385,-122.4079037]];

// d3.json(HEATMAP_API, function(error, json){
//   nodes = json.geometries;

//   init();
//   renderPoints(nodes, selectedType, layers.heatmap, 'point');
//   renderCars(cars);
// });

