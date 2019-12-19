package _ruler_h;

use strict;
use warnings;

use Rect;


use base 'Rect';


## Size_batton coords
sub get_sb_coords { }
sub store {}

sub on_move {
	my( $shape, $e, $h ) =  @_;

	my $dx =  $e->motion_x - $h->{ event_old_x };
	$h->{ event_old_x } =  $e->motion_x;
	my $dy     =  0;
	my $border =  1;
	$shape->move_to( $shape->calc_move_values( $dx, $dy ), $border );

	my $length =  $shape->{ parent }{ w } - $shape->{ w };
	my $pos    =  $shape->{ x };
	$shape->{ parent }{ pos_h } =  $pos / $length;
	# print $shape->{ parent }{ pos }, "\n";

}



package HScrollBar;

use strict;
use warnings;

use Rect;
use Color;


use base 'Rect';



sub store { }

sub new {
	my( $scroll, $dimension ) =  ( shift, shift );

	$scroll =  $scroll->SUPER::new( @_ );

	my $view  =  $scroll->{ w } / $dimension;
	# Nothing to scroll: 100% data is displayed
	$view < 1   or return $scroll;


	my $ruler =  _ruler_h->new(
		0, 0,                                      # X Y
		$scroll->{ w },                            # Width
		limit_min( $scroll->{ h } *$view, 10 ),    # Height
		Color->new( 50, 250, 50 )                  # Color
	);
	$scroll->children( $ruler );

	$scroll->{ pos_h } =  0;


	return $scroll;
}



## Size_batton coords
sub get_sb_coords { }
sub on_move { }


sub limit_min {
	my( $value, $min ) =  @_;

	return $value >= $min? $value : $min;
}



sub limit_max {
	my( $value, $max ) =  @_;

	return $value <= $max? $value : $max;
}


1;
