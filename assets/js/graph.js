(function(global, d3) {
  "use strict";

  var graph = {};

  // Gráfico de Bolhas
  graph.Bubble = function(options) {
    // Define valores padrão para argumentos
    var context = options.context || "body",
        diameter = options.size || 960;

    // Define formação e escala de cores
    var format = d3.format(".d"),
        color = d3.scale.category20c();

    // Define o layout do gráfico
    var bubble = d3.layout.pack()
      .sort(null)
      .size([diameter, diameter])
      .padding(1.5);

    // Cria o svg e insere na página
    var svg = d3.select(context)
      .append("div")
        .attr("class", "graph")
      .append("div")
        .attr("class", "bubble_chart")
      .append("svg")
        .attr("width", diameter)
        .attr("height", diameter);

    // Cria e insere os nodos
    var node = svg.selectAll(".node")
      .data(bubble.nodes(classes(options.data))
      .filter(function(d) {
        return !d.children;
      }))
      .enter()
      .append("g")
        .attr("class", "node")
        .attr("transform", function(d) {
          return "translate(" + d.x + "," + d.y + ")";
        });

    // Isere um titulo para cada nodo
    node.append("title")
      .text(function(d) {
        return d.className + ": " + format(d.value);
      });

    // Insere as bolhas (circulos) para cada nodo
    node.append("circle")
      .attr("class", "circle")
      .attr("r", function(d) {
        return d.r;
      })
      .style("fill", function(d) {
        return color(d.packageName);
      });

    // Insere o texto (descrição) para cada nodo
    node.append("text")
      .attr("dy", ".3em")
      .style("text-anchor", "middle")
      .text(function(d) {
        return d.className.substring(0, d.r / 3);
      });

    // Retorna uma hierarquia achatada contendo todos os nodos de folha na raiz.
    function classes(root) {
      var classes = [];

      function recurse(name, node) {
        if (node.children) {
          node.children.forEach(function(child) {
            recurse(node.name, child);
          });
        } else {
          classes.push({
            packageName: name, className: node.name, value: node.size
          });
        }
      }

      recurse(null, root);
      return {children: classes};
    }

    return this;
  };

  // Gráfico de Barras
  graph.Bar = function(options) {
    // Define valores padrão para argumentos
    var context  = options.context || "body",
        width = options.size || 900,
        height;

    // Define largura das barras    
    var barHeight = 20;

    // Define as margens
    var margin = {top: 20, right: 20, bottom: 20, left: 180};
    
    // Filtro para remover objetos com valor 0
    options.data = options.data.filter(function(item) {
      return (item.size > 0);
    });

    // Ajusta o tamanho
    width -= margin.left + margin.right;
    height = options.data.length * barHeight;

    // Define a escala para x e y
    var x = d3.scale.linear()
      .range([0, width]);

    var y = d3.scale.ordinal()
      .rangeRoundBands([0, height], .1);

    // Define o dominio para x e y
    x.domain([0, d3.max(options.data, function(d) {
      return d.size;
    })]);

    y.domain(options.data.map(function(d) {
      return d.name;
    }));

    // Define os eixos x e y
    var xAxis = d3.svg.axis()
      .scale(x)
      .orient("top");

    var yAxis = d3.svg.axis()
      .scale(y)
      .tickSize(5, 0)
      .orient("left");

    // Cria o svg e insere na página
    var svg = d3.select(context)
      .append("div")
        .attr("class", "graph")
      .append("div")
        .attr("class", "bar_chart")
      .append("svg")
        .attr("width", width + margin.left + margin.right)
        .attr("height", height + margin.top + margin.bottom)
      .append("g")
        .attr("transform", "translate(" + margin.left + "," + margin.top + ")");

    // Insere os eixos
    svg.append("g")
      .attr("class", "x axis")
      .call(xAxis);

    svg.append("g")
      .attr("class", "y axis")
      .attr("transform", "translate(-10, 0)")
      .call(yAxis)
      .selectAll("text")
      .attr("dy", ".35em")
      .style("text-anchor", "left");

    // Insere as barras  
    svg.selectAll(".bar")
      .data(options.data)
      .enter()
      .append("rect")
        .attr("class", "bar")
        .attr("y", function(d) {
          return y(d.name);
        })
        .attr("width", function(d) {
          return  x(d.size);
        })
        .attr("height", barHeight - 2)
      .append("title")
        .text(function(d) {
          return d.name + ": " + d.size;
        });

    return this;
  };

  // Gráfico de Dashboard (hisatograma + pizza + legenda)
  graph.Dashboard = function(options) {
    // Define valores padrão para argumentos
    var context  = options.context || "body";

    // Define as cores para os gráficos
    var barColor = "steelblue";
    function segColor(c) {
      return {low: "#807dba", mid: "#e08214", high: "#41ab5d"}[c];
    }

    // Calcula o total para cada estado.
    options.data.forEach(function(d) {
      d.total = d.freq.low + d.freq.mid + d.freq.high;
    });

    var tF = ["low", "mid", "high"].map(function(d) { 
      return {type: d, freq: d3.sum(options.data.map(function(t) {
        return t.freq[d];
      }))}; 
    });    

    var sF = options.data.map(function(d) {
      return [d.State, d.total];
    });

    // Implementação para o histograma
    var histograma_chart = (function Histograma(data) {
      // Define margem e tamanho
      var histograma_chart = {},
          margin = {top: 60, right: 0, bottom: 30, left: 0},
          width = 500 - margin.left - margin.right,
          height = 300 - margin.top - margin.bottom;

      // Cria e insere o svg para o histograma
      var svg = d3.select(context)
          .append("div")
            .attr("class", "graph")
          .append("svg")
            .attr("class", "dashboard_chart")
            .attr("width", width + margin.left + margin.right)
            .attr("height", height + margin.top + margin.bottom)
          .append("g")
            .attr("transform", "translate(" + margin.left + "," + margin.top + ")");

      // Define o mapeamento de dados para o eixo x e y
      var x = d3.scale.ordinal()
                .rangeRoundBands([0, width], 0.1)
                .domain(data.map(function(d) {
                  return d[0];
                }));

      var y = d3.scale.linear()
                .range([height, 0])
                .domain([0, d3.max(data, function(d) {
                  return d[1];
                })]);

      // Define o eixo x
      var xAxis = d3.svg.axis()
                    .scale(x)
                    .orient("bottom");

      // Insere o eixo x
      svg.append("g").
        attr("class", "x axis")
        .attr("transform", "translate(0," + height + ")")
        .call(xAxis);

      // Cria e isnere as barras
      svg.selectAll(".bar")
        .data(data)
        .enter()
        .append("g")
          .attr("class", "bar")
        .append("rect")
          .attr("x", function(d) { 
            return x(d[0]);
          })
          .attr("y", function(d) {
            return y(d[1]);
          })
          .attr("width", x.rangeBand())
          .attr("height", function(d) {
            return height - y(d[1]);
          })
          .attr("fill", barColor)
          .on("mouseover", mouseover)
          .on("mouseout", mouseout)
        .append("text")
          .text(function(d) {
            return d3.format(",")(d[1]);
          })
          .attr("x", function(d) {
            return x(d[0]) + x.rangeBand() / 2;
          })
          .attr("y", function(d) {
            return y(d[1]) - 5;
          })
          .attr("text-anchor", "middle");

      function mouseover(d) {
        var st = options.data.filter(function(s) {
              return s.State == d[0];
            })[0],
            data = d3.keys(st.freq).map(function(s) {
              return {type: s, freq: st.freq[s]};
            });

        pie_chart.update(data);
        legend_chart.update(data);
      }

      function mouseout(d) {
        pie_chart.update(tF);
        legend_chart.update(tF);
      }

      histograma_chart.update = function(data, color) {
        y.domain([0, d3.max(data, function(d) {
          return d[1];
        })]);

        var bars = svg.selectAll(".bar").data(data);

        bars.select("rect")
          .transition()
          .duration(500)
          .attr("y", function(d) {
            return y(d[1]);
          })
          .attr("height", function(d) {
            return height - y(d[1]);
          })
          .attr("fill", color);

        bars.select("text")
          .transition()
          .duration(500)
          .text(function(d) {
            return d3.format(",")(d[1]);
          })
          .attr("y", function(d) {
            return y(d[1]) - 5;
          });
      };

      return histograma_chart;
    })(sF);

    var pie_chart = (function(data) {
      var pie_chart = {},
          diameter = 250,
          radius = diameter / 2;

      var svg = d3.select(context)
        .append("div")
          .attr("class", "graph")
        .append("svg")
          .attr("class", "dashboard_chart")
          .attr("width", diameter)
          .attr("height", diameter)
        .append("g")
          .attr("transform", "translate(" + radius + "," + radius + ")");

      var arc = d3.svg.arc()
        .outerRadius(radius - 10)
        .innerRadius(0);

      var pie = d3.layout.pie()
          .sort(null)
          .value(function(d) {
            return d.freq;
          });

      svg.selectAll("path")
        .data(pie(data))
        .enter()
        .append("path")
          .attr("d", arc)
          .each(function(d) {
            this._current = d;
          })
          .style("fill", function(d) {
            return segColor(d.data.type);
          })
          .on("mouseover", mouseover)
          .on("mouseout", mouseout);

      pie_chart.update = function(data) {
        svg.selectAll("path")
          .data(pie(data))
          .transition()
          .duration(500)
          .attrTween("d", arcTween);
      };

      function mouseover(d) {
        histograma_chart.update(options.data.map(function(v) {
          return [v.State,v.freq[d.data.type]];
        }), segColor(d.data.type));
      }

      function mouseout(d) {
        histograma_chart.update(options.data.map(function(v) {
          return [v.State,v.total];
        }), barColor);
      }

      function arcTween(a) {
        var i = d3.interpolate(this._current, a);
        this._current = i(0);
        return function(t) {
          return arc(i(t));
        };
      }

      return pie_chart;
    })(tF);

    var legend_chart = (function(data) {
      var legend_chart = {};

      var legend = d3.select(context)
        .append("div")
          .attr("class", "graph")
        .append("div")
          .attr("class", "dashboard_chart")
        .append("table")
          .attr("class", "legend");

      var tr = legend
        .append("tbody")
          .selectAll("tr")
          .data(data)
          .enter()
        .append("tr");

      tr.append("td")
        .append("svg")
          .attr("width", 16)
          .attr("height", 16)
        .append("rect")
          .attr("width", 16)
          .attr("height", 16)
			    .attr("fill", function(d) {
			      return segColor(d.type);
			    });

      tr.append("td")
        .text(function(d) {
          return d.type;
        });

      tr.append("td")
        .attr("class", "legendFreq")
        .text(function(d) {
          return d3.format(",")(d.freq);
        });

      tr.append("td")
        .attr("class", "legendPerc")
        .text(function(d) {
          return getLegend(d,data);
        });

      legend_chart.update = function(data) {
        var l = legend.select("tbody")
          .selectAll("tr")
          .data(data);

        l.select(".legendFreq")
          .text(function(d) {
            return d3.format(",")(d.freq);
          });

        l.select(".legendPerc")
          .text(function(d) {
            return getLegend(d, data);
          });
      };

      function getLegend(d, data) {
        return d3.format("%")(d.freq / d3.sum(data.map(function(v) {
          return v.freq;
        })));
      }

      return legend_chart;
    })(tF);

    return this;
  };

  if (global) {
    global.graph = graph;
  }
})(this, this.d3);