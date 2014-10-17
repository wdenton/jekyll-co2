# Jekyll CO₂

Written by [William Denton](https://www.miskatonic.org/).

This is a plugin for the static web site generator [Jekyll](http://jekyllrb.com/) to show the change in atmospheric CO₂ at the Mauna Loa observatory in Hawaii.  It was inspired by [CO2Now](http://co2now.org/). The data comes from the [NOAA's Earth System Research Laboratory](http://www.esrl.noaa.gov/gmd/ccgg/trends/).

It shows the CO₂ concentrations for the latest known month (usually last month, but sometimes the month before that) over the last 15 years in a text sparkline that looks something like this: ▁▁▂▂▂▂▃▃▃▄▄▄▅▅▅▅▆▆▆▇▇.

In a browser it looks like this:

![Screenshot](screenshot.png)

## How to install

Download `co2.rb` and put it in your `_plugins` directory.  That's all!

## How to use

The plugin creates an include file: `_includes/co2.html`.  Include it in a web page like this:

    {% include co2.html %}

When the page is rendered, the tag will be replaced by a short block of HTML like this:

    <div id="co2">
    <h2>CO₂</h2>
    <span class="sparkline"><span title="355.63">▁</span>[13 years]<span title="395.28">▇</span></span>
    <p><span class="co2_title">Atmospheric CO₂ at Mauna Loa (ppm) in September over the last 20 years</span> </p>
    <span class="co2_source">(<a href="http://www.esrl.noaa.gov/gmd/ccgg/trends/">Source</a>)</span>
    </div>

You could style it with CSS like this:

    #co2 {
      border: thin solid green;
      padding: 5px;
    }

    #co2 .co2_title {
    }

    #co2 .sparkline {
        font-size: smaller;
    }

    #co2 .co2_source {
      font-size: smaller;
    }

## License

GPL v3.  See [LICENSE](LICENSE).
