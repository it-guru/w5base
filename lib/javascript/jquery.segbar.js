(function($) {
    const DEFAULT_WIDTH = "100%";
    const DEFAULT_HEIGHT = "80px";
    const palette = [
        '#26C281',
        '#E9D460',
        '#81CFE0',
        '#F22613',
        '#3A539B',
        '#E67E22',
        '#22A7F0',
        '#C0392B',
        '#663399',
        '#913D88',
        '#F9BF3B',
        '#6C7A89',
        '#DB0A5B',
        '#03A678',
        '#FDE3A7',
        '#6BB9F0',
        '#8E44AD',
        '#D24D57',
        '#CF000F',
        '#86E2D5'
    ];

    $.fn.segbar = function(options) {
        $(this).each(function makeSegBar(index, item) {
            //Get data from options array
            var currentOptions = options[index];
            if(!currentOptions.data || 
               (currentOptions.data.length <= 0)){
                throw new Error("No data provided for chart at position "+
                                index);
            }
            constructBar(this, currentOptions);
        });
        return this;
    };

    function constructBar(element, options) {
        let percentages = getPercentages(options.data);

        for(let i=0; i<options.data.length; i++)  {
            options.data[i].percent = +percentages[i];
        }
        //console.log(options.data);

        element.style.width = options.width ? options.width : DEFAULT_WIDTH;
        element.style.height = options.height ? options.height : DEFAULT_HEIGHT;
        element.classList.add('segbar');
        let colorIt = getNextColor();

        for (var ii=0;ii<options.data.length;ii++){
            var item=options.data[ii];
            let div = document.createElement('div');
            let textcolor="white";

            //Prepare wrapper
            div.style.display = "inline-block";
            div.style.height = "100%";
            div.style.width = parseFloat(item.percent*100)+"%";
            div.style.backgroundColor=
               (item.color) ? item.color : colorIt.next().value;
            div.style.position = "relative";
            div.classList.add('item-wrapper');
            if (div.style.backgroundColor=="yellow"){
                textcolor="black";
            }

            //Percentage span
            let span = document.createElement('span');
            span.textContent = prettifyPercentage(item.percent*100,true);
            span.style.color = textcolor;
            span.style.position = "absolute";
            span.style.bottom = 4;
            span.style.right = 4;
            span.style.fontSize = 10;
            span.classList.add('item-percentage');

            //Title span
            if(item.title && item.title.length > 0) {
                if (item.percent>0.03){
                   let span = document.createElement('span');
                   span.style.position = "absolute";
                   span.style.left = 4;
                   span.style.top = 4;
                   span.style.color = textcolor;
                   span.style.fontWeight = "600";
                   span.textContent = item.title;
                   span.style.fontSize = "11px";
                   span.classList.add('item-title');
                   div.appendChild(span);
                }
                $(div).prop('title',item.title+"\n"+
                          prettifyPercentage(item.percent*100));
            }

            div.appendChild(span);
            element.appendChild(div);
        }
    }

    function prettifyPercentage(percentage,shorted) {
        let pretty = parseFloat(percentage).toFixed(1);
        if (shorted && parseFloat(percentage)<9){
            pretty = parseFloat(percentage).toFixed(0);
        }
        if (shorted && parseFloat(percentage)<4){
           return "";
        }
        let v = pretty.split('.');
        let final = 0;
        if(v[1]) {
            let digits = v[1].split('');
            if(digits[0] == 0 && digits[1] == 0) {
                final = parseFloat(v[0]);
            }
            else {
                final = pretty;
            }
        }
        else {
            final = parseFloat(v[0]);
        }
        return final+"%";
    }

    //Accepts an array of chart data, returns an array of percentages
    function getPercentages(data) {
        let sum = getSum(data);

        return data.map(function (item) {
            return parseFloat(item.value / sum);
        });
    }

    //Accepts an array of chart data, returns the sum of all values
    function getSum(data) {
        return data.reduce(function (sum, item) {
            return sum + item.value;
        }, 0);
    }

    function getNextColor() {
        let i = 0;
        while(true) {
            return(palette[i]);
            i = (i + 1) % palette.length;
        }
    }

}(jQuery));
