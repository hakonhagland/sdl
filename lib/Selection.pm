package Selection;

use AppRect;


use base 'Rect';



sub new {
	my $sel =  shift;

	$sel =  $sel->SUPER::new( @_ );

	$sel->{ sel_start_x } =  $sel->{ x };
	$sel->{ sel_start_y } =  $sel->{ y };

	return $sel;
}



sub get_sb_coords {

	return ( 0, 0, 0, 0 );
}



## Изменение размеров поля selection с отрисовкой
sub on_resize {
	my( $sel, $h, $e ) =  @_;

	$sel->draw_black;
	$sel->resize( $e->motion_x, $e->motion_y );
	$sel->draw;
}



## Изменение размеров поля selection в соответствии с координатами курсора
sub resize {
	my( $sel, $mx, $my ) =  @_;

	my $tx =  $sel->{ sel_start_x };
	my $ty =  $sel->{ sel_start_y };

	if( $mx > $tx ) {
		$sel->{ w } =  $mx - $sel->{ x };
	}
	else {
		$sel->{ x } =  $mx;
		$sel->{ w } =  $tx - $mx;
	}

	if( $my > $ty ) {
		$sel->{ h } =  $my - $sel->{ y };
	}
	else {
		$sel->{ y } =  $my;
		$sel->{ h } =  $ty - $my;
	}
}



1;
