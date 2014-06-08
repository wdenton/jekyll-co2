# Jekyll CO₂

This is a plugin for [Jekyll](http://jekyllrb.com/) to show the change in atmospheric CO₂ at the Mauna Loa observatory in Hawaii.  It was inspired by [CO2Now](http://co2now.org/).

The data comes from the [NOAA's Earth System Research Laboratory](http://www.esrl.noaa.gov/gmd/ccgg/trends/).

## How to install

Download the `co2.rb` file and put it in your `_plugins` directory.

## How to use

The plugin adds a new Liquid tag: `co2`.  To show it, put this in a web page:

    {% co2 %}

When the page is rendered, the tag will be replaced by a short block of HTML that looks like this:

    <div id="co2">
    <span class="co2_head">Atmospheric CO₂ at Mauna Loa:</span>
    <br>
    2014-05: 401.85 ppm.
    <br>
    2013-05: 399.76 ppm.
    <br>
    2012-05: 396.78 ppm.
    <br>
    <span id="co2_foot">(Monthly averages.)</span>
    </div>

It will show the CO₂ concentrations for the latest known month (usually last month, but sometimes the month before that) and same month from the previous year and two years before.
