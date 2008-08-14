package CPAN::Mini::Webserver::Templates;
use strict;
use warnings;
use Convert::UU qw(uudecode);
use Template::Declare::Tags;
use base 'Template::Declare';

private template 'header' => sub {
    my ( $self, $title ) = @_;

    head {
        title {$title};
        link {
            attr {
                rel   => 'stylesheet',
                href  => '/static/css/screen.css',
                type  => 'text/css',
                media => 'screen, projection'
            }
        };
        link {
            attr {
                rel   => 'stylesheet',
                href  => '/static/css/print.css',
                type  => 'text/css',
                media => 'print'
            }
        };
        outs_raw
            '<!--[if IE]><link rel="stylesheet" href="/static/css/ie.css" type="text/css" media="screen, projection"><![endif]-->';
        link {
            attr {
                rel  => 'icon',
                href => '/static/images/favicon.png',
                type => 'image/png',
            }
        };
        link {
            attr {
                rel   => 'search',
                href  => '/static/xml/opensearch.xml',
                type  => 'application/opensearchdescription+xml',
                title => 'minicpan search',
            }
        };

        meta { attr { generator => 'CPAN::Mini::Webserver' } };
    }
};

private template 'footer' => sub {
    my $self    = shift;
    my $version = $CPAN::Mini::Webserver::VERSION;

    div {
        attr { id => "footer" };
        small {
            "Generated by CPAN::Mini::Webserver $version";
        };
    }
};

private template 'author_link' => sub {
    my ( $self, $author ) = @_;
    a {
        attr { href => '/~' . lc( $author->pauseid ) . '/' };
        $author->name;
    };
};

private template 'distribution_link' => sub {
    my ( $self, $distribution ) = @_;
    a {
        attr {    href => '/~'
                . lc( $distribution->cpanid ) . '/'
                . $distribution->distvname
                . '/' };
        $distribution->distvname;
    };
};

private template 'package_link' => sub {
    my ( $self, $package ) = @_;
    my $distribution = $package->distribution;
    a {
        attr {    href => '/package/'
                . lc( $distribution->cpanid ) . '/'
                . $distribution->distvname . '/'
                . $package->package
                . '/' };
        $package->package;
    };
};

private template 'searchbar' => sub {
    my $self = shift;
    my $q    = shift;

    table {
        row {
            form {
                attr { method => 'get', action => '/search/' };
                cell {
                    attr { class => 'searchbar' };
                    outs_raw
                        q|<a href="/"><img src="/static/images/logo.png"></a>|;
                };
                cell {
                    attr { class => 'searchbar' };
                    input {
                        { attr { type => 'text', name => 'q', value => $q } };
                    };
                    input {
                        {
                            attr {
                                type  => 'submit',
                                value => 'Search Mini CPAN'
                                }
                        };
                    };
                };
            };
        };
    };
};

template 'index' => sub {
    my $self = shift;

    html {
        attr { xmlns => 'http://www.w3.org/1999/xhtml' };
        div {
            attr { class => 'container' };
            div {
                attr { class => 'span-24' };
                show( 'header', 'Index' );
                body {
                    show('searchbar');
                    h1 {'Index'};
                    p {'Welcome to CPAN::Mini::Webserver. Start searching!'};
                };
                show('footer');
            };
        };
    };
};

template 'search' => sub {
    my ( $self, $arguments ) = @_;
    my $parse_cpan_authors = $arguments->{parse_cpan_authors};
    my $q                  = $arguments->{q};
    my @authors            = @{ $arguments->{authors} };
    my @distributions      = @{ $arguments->{distributions} };
    my @packages           = @{ $arguments->{packages} };
    html {

        show( 'header', "Search for `$q'" );
        body {
            div {
                attr { class => 'container' };
                div {
                    attr { class => 'span-24' };
                    show( 'searchbar', $q );
                    h1 {
                        outs "Search for ";
                        outs_raw '&#147;';
                        outs $q;
                        outs_raw '&#148;';
                    };
                    if ( @authors + @distributions + @packages ) {
                        outs_raw '<table>';
                        foreach my $author (@authors) {

                            row {
                                cell {
                                    show( 'author_link', $author );

                                };
                            };
                        }

                        foreach my $distribution (@distributions) {
                            row {
                                cell {
                                    show( 'distribution_link',
                                        $distribution );
                                    outs ' by ';
                                    show(
                                        'author_link',
                                        $parse_cpan_authors->author(
                                            $distribution->cpanid
                                        )
                                    );

                                };
                            };
                        }
                        foreach my $package (@packages) {
                            row {
                                cell {
                                    show( 'package_link', $package );
                                    outs ' by ';
                                    show(
                                        'author_link',
                                        $parse_cpan_authors->author(
                                            $package->distribution->cpanid
                                        )
                                    );
                                };
                            };
                        }
                        outs_raw '</table>';
                    } else {
                        p {'No results found.'};
                    }
                    show('footer');
                };
            }
        };

    }
};

template 'author' => sub {
    my ( $self, $arguments ) = @_;
    my $author        = $arguments->{author};
    my $pauseid       = $arguments->{pauseid};
    my $distvname     = $arguments->{distvname};
    my @distributions = @{ $arguments->{distributions} };

    html {
        show( 'header', $author->name );
        body {
            div {
                attr { class => 'container' };
                div {
                    attr { class => 'span-24' };
                    show('searchbar');
                    h1 { show( 'author_link', $author ) };
                    outs_raw '<table>';
                    foreach my $distribution (@distributions) {
                        row {
                            cell {
                                show( 'distribution_link', $distribution );

                            };
                        };
                    }
                    outs_raw '</table>';
                    show('footer');
                };

            };
        };

    }
};

private template 'dependencies' => sub {
    my ( $self, $meta, $pcp ) = @_;

    div {
        attr { class => 'dependencies' };
        h2 {'Dependencies'};
        ul {
            foreach
                my $deptype (qw(requires build_requires configure_requires))
            {
                if ( defined $meta->{$deptype} ) {
                    foreach my $package ( keys %{ $meta->{$deptype} } ) {
                        next if $package eq 'perl';
                        my $d = $pcp->package($package)->distribution;
                        next unless $d;
                        my $distvname = $d->distvname;
                        my $author    = $d->cpanid;
                        li {
                            a {
                                attr { href => "/~$author/$distvname/" };
                                $package;
                            };
                            if ( $deptype =~ /(.*?)_/ ) {
                                outs " ($1 requirement)";
                            }
                        }
                    }
                }
            }
        }
    }
};

private template 'metadata' => sub {
    my ( $self, $meta ) = @_;

    h2 {'Metadata'};
    div {
        attr { class => 'metadata' };
        dl {
            if ( $meta->{abstract} ) {
                dt {'Abstract'};
                dd { $meta->{abstract} };
            }
            if ( $meta->{abstract} ) {
                dt {'License'};
                dd { $meta->{license} };
            }

            foreach my $datum ( keys %{ $meta->{resources} } ) {
                dt { ucfirst $datum; }
                dd {
                    a {
                        attr { href => $meta->{resources}->{$datum}; };
                        $meta->{resources}->{$datum};
                    }

                };
            }
        };
    };
};

template 'distribution' => sub {
    my ( $self, $arguments ) = @_;
    my $author       = $arguments->{author};
    my $pauseid      = $arguments->{pauseid};
    my $distvname    = $arguments->{distvname};
    my $distribution = $arguments->{distribution};
    my @filenames    = @{ $arguments->{filenames} };
    my $meta         = $arguments->{meta};
    my $pcp          = $arguments->{pcp};
    html {
        show( 'header', $author->name . ' > ' . $distvname );
        body {
            div {
                attr { class => 'container' };
                div {
                    attr { class => 'span-24 last' };
                    show('searchbar');
                    h1 {
                        show( 'author_link', $author );
                        outs ' > ';
                        show( 'distribution_link', $distribution );
                    };
                }
                div {
                    attr { class => 'span-18 last' };

                    outs_raw '<table>';
                    foreach my $filename (@filenames) {
                        my $href
                            = ( $filename =~ /\.(pm|PL|pod)$/ )
                            ? "/~$pauseid/$distvname/$filename"
                            : "/raw/~$pauseid/$distvname/$filename";
                        row {
                            cell {
                                a {
                                    attr { href => $href };
                                    $filename;
                                };
                            };
                        };
                    }
                    outs_raw '</table>';
                };
                div {
                    attr { class => 'span-6 last' };
                    show( 'metadata', $meta );
                    show( 'dependencies', $meta, $pcp );
                };
                div {
                    attr { class => 'span-24 last' };
                    show('footer');
                };

            }

        };

    }
};

template 'file' => sub {
    my ( $self, $arguments ) = @_;
    my $author       = $arguments->{author};
    my $distribution = $arguments->{distribution};
    my $filename     = $arguments->{filename};
    my $pauseid      = $arguments->{pauseid};
    my $distvname    = $arguments->{distvname};

    my $file     = $arguments->{filename};
    my $contents = $arguments->{contents};
    my $html     = $arguments->{html};
    html {
        show( 'header',
            $author->name . ' > ' . $distvname . ' > ' . $filename );
        body {
            div {
                attr { class => 'container' };
                div {
                    attr { class => 'span-24' };
                    show('searchbar');
                    h1 {
                        show( 'author_link', $author );
                        outs ' > ';
                        show( 'distribution_link', $distribution );
                        outs ' > ';
                        outs $filename;
                    };

                    a {
                        attr {
                            href => "/raw/~$pauseid/$distvname/$filename" };
                        "See raw file";
                    };
                    if ($html) {
                        div {
                            attr { id => "pod" };
                            outs_raw $html;
                        };
                    } else {
                        pre {$contents};
                    }
                    show('footer');
                };

            };
        };

    }
};

template 'raw' => sub {
    my ( $self, $arguments ) = @_;
    my $author       = $arguments->{author};
    my $distribution = $arguments->{distribution};
    my $filename     = $arguments->{filename};
    my $pauseid      = $arguments->{pauseid};
    my $distvname    = $arguments->{distvname};
    my $contents     = $arguments->{contents};
    my $html         = $arguments->{html};
    html {
        show( 'header',
            $author->name . ' > ' . $distvname . ' > ' . $filename );
        body {
            div {
                attr { class => 'container' };
                div {
                    attr { class => 'span-24' };
                    show('searchbar');
                    h1 {
                        show( 'author_link', $author );
                        outs ' > ';
                        show( 'distribution_link', $distribution );
                        outs ' > ';
                        outs $filename;
                    };
                    if ($html) {
                        div {
                            attr { id => "code" };
                            code {
                                outs_raw $html;
                            };
                        };
                    } else {
                        pre {$contents};
                    }
                    show('footer');
                };

            };
        };

    }
};

template 'opensearch' => sub {
    my $self = shift;
    outs_raw q|<?xml version="1.0" encoding="UTF-8"?>
<OpenSearchDescription xmlns="http://a9.com/-/spec/opensearch/1.1/">
<ShortName>minicpan_webserver</ShortName>
<Description>Search minicpan</Description>
<InputEncoding>UTF-8</InputEncoding>
<Image width="16" height="16">data:image/png,%89PNG%0D%0A%1A%0A%00%00%00%0DIHDR%00%00%00%10%00%00%00%10%08%03%00%00%00(-%0FS%00%00%00%01sRGB%00%AE%CE%1C%E9%00%00%003PLTE8%00%00%05%08%04%16%18%15%1E%1F%1D!%22%20%26(%26%2C-%2B130%3B%3D%3AFHELMKXZWegdxyw%84%86%83%9E%A0%9D%CC%CE%CBjq%F6r%00%00%00%01tRNS%00%40%E6%D8f%00%00%00lIDAT%18%D3u%8FY%0E%C20%0C%05%BD%AF)%ED%FDO%0B%85%10%15%04%EF%C7%1A%7B%2C%D9%00%7Fr%C4W%A3u%EB%2B%EFn%E3sAnr1%8E%E11%D4rq%1Bn%9E%CC%8B%15%C5%01%14u%B2%A0%3EmA9K1Z%BD%5C%C6%87%18%B4%18%8A0%A0Q%2B%C3%CC%232%9D%CE%19%E1%3B%3C%E6%E6%CA%BC%C4%A5%BB%C2%84%FC%D7%DBw%7BS%02%E3Ki%23G%00%00%00%00IEND%AEB%60%82</Image>
<Url type="text/html" method="get" template="http://localhost:2963/search/?q={searchTerms}"/>
</OpenSearchDescription>
|;
};

template 'css_screen' => sub {
    my $self = shift;
    outs_raw
        q|/* -----------------------------------------------------------------------

   Blueprint CSS Framework 0.7.1
   http://blueprintcss.googlecode.com

   * Copyright (c) 2007-2008. See LICENSE for more info.
   * See README for instructions on how to use Blueprint.
   * For credits and origins, see AUTHORS.
   * This is a compressed file. See the sources in the 'src' directory.

----------------------------------------------------------------------- */

/* reset.css */
html, body, div, span, object, iframe, h1, h2, h3, h4, h5, h6, p, blockquote, pre, a, abbr, acronym, address, code, del, dfn, em, img, q, dl, dt, dd, ol, ul, li, fieldset, form, label, legend, table, caption, tbody, tfoot, thead, tr, th, td {margin:0;padding:0;border:0;font-weight:inherit;font-style:inherit;font-size:100%;font-family:inherit;vertical-align:baseline;}
body {line-height:1.5;}
table {border-collapse:separate;border-spacing:0;}
caption, th, td {text-align:left;font-weight:normal;}
table, td, th {vertical-align:middle;}
blockquote:before, blockquote:after, q:before, q:after {content:"";}
blockquote, q {quotes:"" "";}
a img {border:none;}

/* typography.css */
body {font-size:75%;color:#222;background:#fff;font-family:"Helvetica Neue", Helvetica, Arial, sans-serif;}
h1, h2, h3, h4, h5, h6 {font-weight:normal;color:#111;}
h1 {font-size:3em;line-height:1;margin-bottom:0.5em;}
h2 {font-size:2em;margin-bottom:0.75em;}
h3 {font-size:1.5em;line-height:1;margin-bottom:1em;}
h4 {font-size:1.2em;line-height:1.25;margin-bottom:1.25em;height:1.25em;}
h5 {font-size:1em;font-weight:bold;margin-bottom:1.5em;}
h6 {font-size:1em;font-weight:bold;}
h1 img, h2 img, h3 img, h4 img, h5 img, h6 img {margin:0;}
p {margin:0 0 1.5em;}
p img {float:left;margin:1.5em 1.5em 1.5em 0;padding:0;}
p img.right {float:right;margin:1.5em 0 1.5em 1.5em;}
a:focus, a:hover {color:#000;}
a {color:#009;text-decoration:underline;}
blockquote {margin:1.5em;color:#666;font-style:italic;}
strong {font-weight:bold;}
em, dfn {font-style:italic;}
dfn {font-weight:bold;}
sup, sub {line-height:0;}
abbr, acronym {border-bottom:1px dotted #666;}
address {margin:0 0 1.5em;font-style:italic;}
del {color:#666;}
pre, code {margin:1.5em 0;white-space:pre;}
pre, code, tt {font:1em 'andale mono', 'lucida console', monospace;line-height:1.5;}
li ul, li ol {margin:0 1.5em;}
ul, ol {margin:0 1.5em 1.5em 1.5em;}
ul {list-style-type:disc;}
ol {list-style-type:decimal;}
dl {margin:0 0 1.5em 0;}
dl dt {font-weight:bold;}
dd {margin-left:1.5em;}
table {margin-bottom:1.4em;width:100%;}
th {font-weight:bold;background:#C3D9FF;}
th, td {padding:4px 10px 4px 5px;}
tr.even td {background:#E5ECF9;}
tfoot {font-style:italic;}
caption {background:#eee;}
.small {font-size:.8em;margin-bottom:1.875em;line-height:1.875em;}
.large {font-size:1.2em;line-height:2.5em;margin-bottom:1.25em;}
.hide {display:none;}
.quiet {color:#666;}
.loud {color:#000;}
.highlight {background:#ff0;}
.added {background:#060;color:#fff;}
.removed {background:#900;color:#fff;}
.first {margin-left:0;padding-left:0;}
.last {margin-right:0;padding-right:0;}
.top {margin-top:0;padding-top:0;}
.bottom {margin-bottom:0;padding-bottom:0;}

/* grid.css */
.container {width:950px;margin:0 auto;}
.showgrid {background:url(src/grid.png);}
body {margin:1.5em 0;}
div.span-1, div.span-2, div.span-3, div.span-4, div.span-5, div.span-6, div.span-7, div.span-8, div.span-9, div.span-10, div.span-11, div.span-12, div.span-13, div.span-14, div.span-15, div.span-16, div.span-17, div.span-18, div.span-19, div.span-20, div.span-21, div.span-22, div.span-23, div.span-24 {float:left;margin-right:10px;}
div.last {margin-right:0;}
.span-1 {width:30px;}
.span-2 {width:70px;}
.span-3 {width:110px;}
.span-4 {width:150px;}
.span-5 {width:190px;}
.span-6 {width:230px;}
.span-7 {width:270px;}
.span-8 {width:310px;}
.span-9 {width:350px;}
.span-10 {width:390px;}
.span-11 {width:430px;}
.span-12 {width:470px;}
.span-13 {width:510px;}
.span-14 {width:550px;}
.span-15 {width:590px;}
.span-16 {width:630px;}
.span-17 {width:670px;}
.span-18 {width:710px;}
.span-19 {width:750px;}
.span-20 {width:790px;}
.span-21 {width:830px;}
.span-22 {width:870px;}
.span-23 {width:910px;}
.span-24, div.span-24 {width:950px;margin:0;}
.append-1 {padding-right:40px;}
.append-2 {padding-right:80px;}
.append-3 {padding-right:120px;}
.append-4 {padding-right:160px;}
.append-5 {padding-right:200px;}
.append-6 {padding-right:240px;}
.append-7 {padding-right:280px;}
.append-8 {padding-right:320px;}
.append-9 {padding-right:360px;}
.append-10 {padding-right:400px;}
.append-11 {padding-right:440px;}
.append-12 {padding-right:480px;}
.append-13 {padding-right:520px;}
.append-14 {padding-right:560px;}
.append-15 {padding-right:600px;}
.append-16 {padding-right:640px;}
.append-17 {padding-right:680px;}
.append-18 {padding-right:720px;}
.append-19 {padding-right:760px;}
.append-20 {padding-right:800px;}
.append-21 {padding-right:840px;}
.append-22 {padding-right:880px;}
.append-23 {padding-right:920px;}
.prepend-1 {padding-left:40px;}
.prepend-2 {padding-left:80px;}
.prepend-3 {padding-left:120px;}
.prepend-4 {padding-left:160px;}
.prepend-5 {padding-left:200px;}
.prepend-6 {padding-left:240px;}
.prepend-7 {padding-left:280px;}
.prepend-8 {padding-left:320px;}
.prepend-9 {padding-left:360px;}
.prepend-10 {padding-left:400px;}
.prepend-11 {padding-left:440px;}
.prepend-12 {padding-left:480px;}
.prepend-13 {padding-left:520px;}
.prepend-14 {padding-left:560px;}
.prepend-15 {padding-left:600px;}
.prepend-16 {padding-left:640px;}
.prepend-17 {padding-left:680px;}
.prepend-18 {padding-left:720px;}
.prepend-19 {padding-left:760px;}
.prepend-20 {padding-left:800px;}
.prepend-21 {padding-left:840px;}
.prepend-22 {padding-left:880px;}
.prepend-23 {padding-left:920px;}
div.border {padding-right:4px;margin-right:5px;border-right:1px solid #eee;}
div.colborder {padding-right:24px;margin-right:25px;border-right:1px solid #eee;}
.pull-1 {margin-left:-40px;}
.pull-2 {margin-left:-80px;}
.pull-3 {margin-left:-120px;}
.pull-4 {margin-left:-160px;}
.pull-5 {margin-left:-200px;}
.pull-6 {margin-left:-240px;}
.pull-7 {margin-left:-280px;}
.pull-8 {margin-left:-320px;}
.pull-9 {margin-left:-360px;}
.pull-10 {margin-left:-400px;}
.pull-11 {margin-left:-440px;}
.pull-12 {margin-left:-480px;}
.pull-13 {margin-left:-520px;}
.pull-14 {margin-left:-560px;}
.pull-15 {margin-left:-600px;}
.pull-16 {margin-left:-640px;}
.pull-17 {margin-left:-680px;}
.pull-18 {margin-left:-720px;}
.pull-19 {margin-left:-760px;}
.pull-20 {margin-left:-800px;}
.pull-21 {margin-left:-840px;}
.pull-22 {margin-left:-880px;}
.pull-23 {margin-left:-920px;}
.pull-24 {margin-left:-960px;}
.pull-1, .pull-2, .pull-3, .pull-4, .pull-5, .pull-6, .pull-7, .pull-8, .pull-9, .pull-10, .pull-11, .pull-12, .pull-13, .pull-14, .pull-15, .pull-16, .pull-17, .pull-18, .pull-19, .pull-20, .pull-21, .pull-22, .pull-23, .pull-24 {float:left;position:relative;}
.push-1 {margin:0 -40px 1.5em 40px;}
.push-2 {margin:0 -80px 1.5em 80px;}
.push-3 {margin:0 -120px 1.5em 120px;}
.push-4 {margin:0 -160px 1.5em 160px;}
.push-5 {margin:0 -200px 1.5em 200px;}
.push-6 {margin:0 -240px 1.5em 240px;}
.push-7 {margin:0 -280px 1.5em 280px;}
.push-8 {margin:0 -320px 1.5em 320px;}
.push-9 {margin:0 -360px 1.5em 360px;}
.push-10 {margin:0 -400px 1.5em 400px;}
.push-11 {margin:0 -440px 1.5em 440px;}
.push-12 {margin:0 -480px 1.5em 480px;}
.push-13 {margin:0 -520px 1.5em 520px;}
.push-14 {margin:0 -560px 1.5em 560px;}
.push-15 {margin:0 -600px 1.5em 600px;}
.push-16 {margin:0 -640px 1.5em 640px;}
.push-17 {margin:0 -680px 1.5em 680px;}
.push-18 {margin:0 -720px 1.5em 720px;}
.push-19 {margin:0 -760px 1.5em 760px;}
.push-20 {margin:0 -800px 1.5em 800px;}
.push-21 {margin:0 -840px 1.5em 840px;}
.push-22 {margin:0 -880px 1.5em 880px;}
.push-23 {margin:0 -920px 1.5em 920px;}
.push-24 {margin:0 -960px 1.5em 960px;}
.push-1, .push-2, .push-3, .push-4, .push-5, .push-6, .push-7, .push-8, .push-9, .push-10, .push-11, .push-12, .push-13, .push-14, .push-15, .push-16, .push-17, .push-18, .push-19, .push-20, .push-21, .push-22, .push-23, .push-24 {float:right;position:relative;}
.box {padding:1.5em;margin-bottom:1.5em;background:#E5ECF9;}
hr {background:#ddd;color:#ddd;clear:both;float:none;width:100%;height:.1em;margin:0 0 1.45em;border:none;}
hr.space {background:#fff;color:#fff;}
.clearfix:after, .container:after {content:".";display:block;height:0;clear:both;visibility:hidden;}
.clearfix, .container {display:inline-block;}
* html .clearfix, * html .container {height:1%;}
.clearfix, .container {display:block;}
.clear {clear:both;}

/* forms.css */
label {font-weight:bold;}
fieldset {padding:1.4em;margin:0 0 1.5em 0;border:1px solid #ccc;}
legend {font-weight:bold;font-size:1.2em;}
input.text, input.title, textarea, select {margin:0.5em 0;border:1px solid #bbb;}
input.text:focus, input.title:focus, textarea:focus, select:focus {border:1px solid #666;}
input.text, input.title {width:300px;padding:5px;}
input.title {font-size:1.5em;}
textarea {width:390px;height:250px;padding:5px;}
.error, .notice, .success {padding:.8em;margin-bottom:1em;border:2px solid #ddd;}
.error {background:#FBE3E4;color:#8a1f11;border-color:#FBC2C4;}
.notice {background:#FFF6BF;color:#514721;border-color:#FFD324;}
.success {background:#E6EFC2;color:#264409;border-color:#C6D880;}
.error a {color:#8a1f11;}
.notice a {color:#514721;}
.success a {color:#264409;}

/* /home/acme/hg/CPAN-Mini-Webserver/root/static/css/my-screen.css */
h1 {font-size:2em;clear:both;margin-top:10px;}
h2 {font-size:1.7em;clear:both;}
h3 {font-size:1.4em;clear:both;}
body {background:#ffffff;font-size:100%;font-family:Georgia, "Times New Roman", Times, serif;}
pre, code, tt {font-size:80%;}
td.searchbar {vertical-align:middle;}
div#searchbar {min-height:10em;display:table-cell;vertical-align:middle;}
#code {font-size:120%;font-family:monospace;padding:10px 10px 10px 10px;}
#eval {font-family:monospace;border-width:1px;border-style:solid solid solid solid;border-color:#ccc;padding:5px 5px 5px 5px;}
.line_number {color:#aaaaaa;}
.comment {color:#228B22;}
.symbol {color:#00688B;}
.word {color:#8B008B;font-weight:bold;}
.structure {color:#000000;}
.number {color:#B452CD;}
.single {color:#CD5555;}
.double {color:#CD5555;}


/* buttons */
a.button, button {display:block;float:left;margin:0 0.583em 0.667em 0;padding:5px 10px 5px 7px;border:1px solid #dedede;border-top:1px solid #eee;border-left:1px solid #eee;background-color:#f5f5f5;font-family:"Lucida Grande", Tahoma, Arial, Verdana, sans-serif;font-size:100%;line-height:130%;text-decoration:none;font-weight:bold;color:#565656;cursor:pointer;}
button {width:auto;overflow:visible;padding:4px 10px 3px 7px;}
button[type] {padding:4px 10px 4px 7px;line-height:17px;}
*:first-child+html button[type] {padding:4px 10px 3px 7px;}
button img, a.button img {margin:0 3px -3px 0 !important;padding:0;border:none;width:16px;height:16px;float:none;}
button:hover, a.button:hover {background-color:#dff4ff;border:1px solid #c2e1ef;color:#336699;}
a.button:active {background-color:#6299c5;border:1px solid #6299c5;color:#fff;}
body .positive {color:#529214;}
a.positive:hover, button.positive:hover {background-color:#E6EFC2;border:1px solid #C6D880;color:#529214;}
a.positive:active {background-color:#529214;border:1px solid #529214;color:#fff;}
body .negative {color:#d12f19;}
a.negative:hover, button.negative:hover {background:#fbe3e4;border:1px solid #fbc2c4;color:#d12f19;}
a.negative:active {background-color:#d12f19;border:1px solid #d12f19;color:#fff;}
|;
};

template 'css_print' => sub {
    my $self = shift;
    outs_raw
        q|/* -----------------------------------------------------------------------

   Blueprint CSS Framework 0.7.1
   http://blueprintcss.googlecode.com

   * Copyright (c) 2007-2008. See LICENSE for more info.
   * See README for instructions on how to use Blueprint.
   * For credits and origins, see AUTHORS.
   * This is a compressed file. See the sources in the 'src' directory.

----------------------------------------------------------------------- */

/* print.css */
body {line-height:1.5;font-family:"Helvetica Neue", Helvetica, Arial, sans-serif;color:#000;background:none;font-size:10pt;}
.container {background:none;}
hr {background:#ccc;color:#ccc;width:100%;height:2px;margin:2em 0;padding:0;border:none;}
hr.space {background:#fff;color:#fff;}
h1, h2, h3, h4, h5, h6 {font-family:"Helvetica Neue", Arial, "Lucida Grande", sans-serif;}
code {font:.9em "Courier New", Monaco, Courier, monospace;}
img {float:left;margin:1.5em 1.5em 1.5em 0;}
a img {border:none;}
p img.top {margin-top:0;}
blockquote {margin:1.5em;padding:1em;font-style:italic;font-size:.9em;}
.small {font-size:.9em;}
.large {font-size:1.1em;}
.quiet {color:#999;}
.hide {display:none;}
a:link, a:visited {background:transparent;font-weight:700;text-decoration:underline;}
a:link:after, a:visited:after {content:" (" attr(href) ") ";font-size:90%;}
|;
};

template 'css_ie' => sub {
    my $self = shift;
    outs_raw
        q|/* -----------------------------------------------------------------------

   Blueprint CSS Framework 0.7.1
   http://blueprintcss.googlecode.com

   * Copyright (c) 2007-2008. See LICENSE for more info.
   * See README for instructions on how to use Blueprint.
   * For credits and origins, see AUTHORS.
   * This is a compressed file. See the sources in the 'src' directory.

----------------------------------------------------------------------- */

/* ie.css */
body {text-align:center;}
.container {text-align:left;}
* html .column {overflow-x:hidden;}
* html legend {margin:-18px -8px 16px 0;padding:0;}
ol {margin-left:2em;}
sup {vertical-align:text-top;}
sub {vertical-align:text-bottom;}
html>body p code {*white-space:normal;}
hr {margin:-8px auto 11px;}
|;
};

template 'images_logo' => sub {
    my $self      = shift;
    my $uuencoded = q|begin 644 logo.png
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
-VP````!)14Y$KD)@@@``
`
end
|;
    my ( $string, $filename, $mode ) = uudecode($uuencoded);
    outs_raw $string;
};

template 'images_favicon' => sub {
    my $self      = shift;
    my $uuencoded = q|begin 644 favicon.png
MB5!.1PT*&@H````-24A$4@```!`````0"`,````H+0]3`````7-21T(`KLX<
MZ0```#-03%1%.```!0@$%A@5'A\=(2(@)B@F+"TK,3,P.STZ1DA%3$U+6%I7
M96=D>'EWA(:#GJ"=S,[+:G'V<@````%T4DY3`$#FV&8```!L241!5!C3=8]9
M#L(P#`6]KRGM_4\+A1`5!._'&GLLV0!_<L17HW7K*^]NXW-!;G(QCN$QU')Q
M&VZ>S(L5Q0$4=;*@/FU!.4LQ6KU<QH<8M!B*,*!1*\/,(S*=SAGA.SSFYLJ\
=Q*6[PH3\U]MW>U,"XTMI(T<`````245.1*Y"8((`
`
end
|;
    my ( $string, $filename, $mode ) = uudecode($uuencoded);
    outs_raw $string;
};

__END__

=head1 NAME

CPAN::Mini::Webserver::Templates - Templates for CPAN::Mini::Webserver

=head1 DESCRIPTION

This module holds the templates, CSS and images for 
CPAN::Mini::Webserver.

=head1 AUTHOR

Leon Brocard <acme@astray.com>

=head1 COPYRIGHT

Copyright (C) 2008, Leon Brocard.

This module is free software; you can redistribute it or 
modify it under the same terms as Perl itself.
