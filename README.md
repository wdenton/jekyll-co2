# Jekyll CO₂

Written by [William Denton](https://www.miskatonic.org/).

This is a plugin for the static web site generator [Jekyll](http://jekyllrb.com/) to show the change in atmospheric CO₂ at the Mauna Loa observatory in Hawaii.  It was inspired by [CO2Now](http://co2now.org/). The data comes from the [NOAA's Earth System Research Laboratory](http://www.esrl.noaa.gov/gmd/ccgg/trends/).

In a browser it looks like this:

![Screenshot](screenshot.png)

## How to install

Download `co2.rb` and put it in your `_plugins` directory.  That's all!

This CSV file downloaded is stored in your `_data` directory.  If you don't have one, it will be created.

## How to use

The plugin creates an include file: `_includes/co2.html`.  Include it in a web page like this:

    {% include co2.html %}

Look at the file (or the code) to see exactly how it's structured.

You could style it with CSS like this:

    #co2 {
	}

    #co2 #co2_inside {
      border: thin solid red;
      padding: 5px;
    }

    #co2 > .highlight {
      color: red;
    }

    #co2 .co2_source {
      font-size: smaller;
    }

## License

GPL v3.  See [LICENSE](LICENSE).
