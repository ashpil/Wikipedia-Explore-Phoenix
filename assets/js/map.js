import mapboxgl from 'mapbox-gl';

mapboxgl.accessToken = 'pk.eyJ1IjoiYXNocGlsIiwiYSI6ImNrNGRjbXdpOTAwbHQza21vbWE2aGlkZTYifQ.7QOHc9uZDLDF2FT95M76Ig';

const map = new mapboxgl.Map({
    container: 'map',
    style: 'mapbox://styles/ashpil/ck4dcpj9t0avf1dn0nn3ffoid',
    minZoom: 2,
    zoom: 2.01
});

map.on('load', function() {

    // add empty placeholder source
    map.addSource('locations', {
        type: 'geojson',
        data: { type: 'FeatureCollection', features: []}
    });

    // every time button is clicked...
    document.getElementById("button").addEventListener("click", function(){

        // prepare data for post request
        const center = map.getCenter();
		const data = {
			"latitude": center.lat,
			"longitude": center.lng,
			"south": map.getBounds().getSouth(),
		};
        
        // get wikipedia response through wrapper, then...
        const response = fetch("/api", {
            method: 'POST',
            body: JSON.stringify(data)
        }).then(response => response.json()).then(json => {
            
            // get rid of all old markers
            let elements = document.getElementsByClassName("marker");
            while (elements.length > 0) {
                  elements[0].parentNode.removeChild(elements[0]);
            }
            
            // update source data
            var desc = document.getElementById("description");
            var title = document.getElementById("title");
            map.getSource('locations').setData(json);
            console.log(map.getSource('locations'))
            // add new markers
            json.features.forEach(function(marker) {

                // create a HTML element for each feature
                let el = document.createElement('div');
                el.className = 'marker';

                // on click, update sidebar and set marker as active
                el.addEventListener('click', function(){
                    let active = document.getElementById("active-marker");
                    if (active != null){
                        active.removeAttribute('id');
                    };
                    desc.innerHTML = marker.properties.extract;
                    title.innerHTML= marker.properties.title;
                    el.id = "active-marker";
                });
              
                // make a marker for each feature and add to the map
                new mapboxgl.Marker(el)
                  .setLngLat(marker.geometry.coordinates)
                  .addTo(map);
            });
        });
    });
});