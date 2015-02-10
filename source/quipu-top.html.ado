<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <title>Regression Output</title>

  <meta name="description" content="Stata Regression Output (quipu.ado)">
  <meta name="author" content="Sergio Correia">

  <script src="https://cdn.mathjax.org/mathjax/latest/MathJax.js?config=TeX-AMS-MML_HTMLorMML"></script>
  <!--
  <script src="https://ajax.googleapis.com/ajax/libs/jquery/2.1.3/jquery.min.js"></script>
  <script type="application/javascript" src="https://cdn.rawgit.com/ndp/align-column/master/jquery.align-column.js"></script>
  <script type="text/javascript">
      $(function () {
        $('table.estimates').alignColumn([1, 2, 3]);
      });
  </script>
  -->

  <style type="text/css">
    body {
      font: normal 1.3em Verdana; /* = 13px */
    }

    table.estimates {
      font-family: "Myriad Pro", "Segoe UI", "Helvetica", Arial;
      border-top: 3px solid black;
      border-bottom: 3px solid black;
      border-collapse: collapse;
      table-layout: auto;
      empty-cells: show;
    }

    table.estimates td,th {
      padding: .1em 1em;
    }

    table.estimates p.underline {
      margin-left:10px;
      margin-right:10px;
      border-bottom:1px solid black;
    }

    table.estimates > tbody,tfoot {
      border-top: 1px solid black;
      /*margin-bottom: 5px solid black;*/
    }

    table.estimates th {
      background-color: #fff;
      padding-bottom: 15px;
    }

    table.estimates td {
      text-align: "." right;
    }


    caption {
      caption-side: top; /* bottom top */
    }

    p.estimates-notes {
      margin: 0px;
    }
    p.estimates-notes > em {
      font-variant: small-caps;
    }
    
    dl.estimates-notes {
      padding: 0.5em;
      margin: 0px;
    }
    dl.estimates-notes > dt {
      float: left;
      clear: left;
      width: 20px;
      text-align: right;
    }
    dl.estimates-notes > dt:after {
        content: " ";
      }
    dl.estimates-notes > dd {
      margin: 0 0 0 30px;
      padding: 0 0 0.5em 0;
    }
    summary {
      margin: 20px -20px 0 0; 
    }

  </style>
</head>

<body>
