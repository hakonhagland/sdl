package Rect;

# use strict;
# use warnings;


use Scalar::Util qw(weaken);
use AppRect;
use Color;
use Shape;


use base 'Shape';


my $START_W =  50;
my $START_H =  30;

my $y_offset_n =  0;
my $x_offset   =  50;
my $y_offset   =  50;
sub new {
	if( ref $_[1] eq 'Schema::Result::Rect' ) {
		my( $rect, $db_rect ) =  @_;

		$rect =  $rect->new(
			$db_rect->x, $db_rect->y, $db_rect->w, $db_rect->h,
			Color->new( $db_rect->r, $db_rect->g, $db_rect->b, $db_rect->a ),
		);
		$rect->{ id } =  $db_rect->id;
		return $rect;
	}


	my( $rect, $x, $y, $w, $h, $c ) =  @_;

	$x //=  ($x_offset += 30);
	$y //=  $y_offset_n * 5  + ($y_offset +=  10);

	if( $x_offset > 600 ) {
		$x_offset =  40;
		$y_offset =  50;
		$y_offset_n++;
	}

	my %rect = (
		x      => $x,
		y      => $y,
		w      => $w // $START_W,
		h      => $h // $START_H,
		c      => $c // Color->new,
	);

	return bless \%rect, $rect;
}



sub draw_black {
	my( $rect, $screen, $x, $y ) = @_;

	$screen //=  AppRect::SCREEN();
	$x //=  0;
	$y //=  0;

	$x += $rect->{ x };
	$y += $rect->{ y };


	$screen->draw_rect([
		$x,
		$y,
		$rect->{ w },
		$rect->{ h },
	],[ 0, 0, 0, 0 ]);
}



sub draw {
	my( $rect, $screen, $x, $y ) = @_;

	$screen //=  AppRect::SCREEN();
	$x //=  0;
	$y //=  0;

	$x += $rect->{ x };
	$y += $rect->{ y };

	$screen->draw_rect([
		$x,
		$y,
		$rect->{ w },
		$rect->{ h },
	],[
		255,255,255,255
	]);
	#circuit
	$screen->draw_rect([
		$x +1,
		$y +1,
		$rect->{ w }-2,
		$rect->{ h }-2,
	],[
		$rect->{ c }->get()
	]);

	#size_button
	$screen->draw_rect([
		$x + $rect->{ w } -15,
		$y + $rect->{ h } -10,
		15,
		10,
	],[
		33, 200, 150, 255
	]);


	if( $rect->{ children } ) {
		# my $h =  10;
		for my $s ( $rect->{ children }->@* ) {
		# 	$s->{ x }      =  $rect->{ x } + 10;
		# 	$s->{ y }      =  $rect->{ y } + $h;
		# 	$s->{ c }{ r } =  $rect->{ c }{ r } + 80;

		# 	$h +=  $s->{ h } +10;

			$s->draw( $screen, $x, $y );
		}
	}
}



sub draw_black_group {
	my( $squares, $app, $x, $y ) = @_;

	for my $rect( @$squares ) {
		if( $rect->Util::mouse_target_square( $x, $y ) ) {
			$rect->draw_black( $app );
		}
	}
}



sub is_over {
	my( $rect, $x, $y ) =  @_;

	my $bool =  Util::mouse_target_square( $rect, $x, $y );
	if( $bool ) {
		for my $r ( $rect->{ children }->@* ) {
			if( my $over = $r->is_over( $x - $rect->{ x }, $y - $rect->{ y } ) ) {
				return $over;
			}
		}

		return {
			target 	=> $rect,
			x      	=> $x,
			y      	=> $y,
			dx      => $x - $rect->{ x },
			dy      => $y - $rect->{ y },
		};
	}

	return;
}



sub is_inside {
	my( $rect, $x, $y, $w, $h ) =  @_;

	return $rect->{ x } > $x  &&  $rect->{ x } + $rect->{ w } < $x + $w
		&& $rect->{ y } > $y  &&  $rect->{ y } + $rect->{ h } < $y + $h;
}



sub store {
	my( $rect ) =  @_;

	if( $rect->{ id } ) {
		my $row =  Util::db()->resultset( 'Rect' )->search({
			id => $rect->{ id },
		})->first;
		$row->update({
			$rect->%{qw/ x y w h parent_id/},
			$rect->{ c }->geth,
		});
	}
	elsif( $rect->{ parent } ) {
		my $row =  Util::db()->resultset( 'Rect' )->create({
			$rect->%{qw/ x y w h /},
			$rect->{ c }->geth,
		});

		$rect->{ id } =  $row->id;
	}

	for my $r ( $rect->{ children }->@* ) {
		$r->store;
	}

	return $rect;
}



sub parent_id {
	my( $rect, $id ) =  @_;

	Util::db()->resultset( 'Rect' )->search({
		id => $rect->{ id },
	})->first->update({ parent_id => $id });

	$rect->{ parent_id } =  $id;
}



#назначение родителя его же детям
sub load_parent_data {
	my( $rect ) =  @_;
	for my $child( $rect->{ children }->@* ) {
		$child->{ parent } =   $rect;
		weaken $child->{ parent };
	}
}



# sub moving_on {
# 	my( $shape, $e ) =  @_;

# 	$shape->save_state( $e->motion_x, $e->motion_y );
# 	$shape->{ c } =  Color->new( 0, 0, 200 );
# }



sub save_state {
	my( $rect, $tp_x, $tp_y ) =  @_; # tp - take point


	$rect->{ start_x } =  $rect->{ x };
	$rect->{ start_y } =  $rect->{ y };

	$rect->{ start_c } =  $rect->{ c };

	$rect->{ dx } =  $tp_x - $rect->{ x };
	$rect->{ dy } =  $tp_y - $rect->{ y };
}



sub restore_state {
	my( $rect ) =  @_;

	$rect->{ c } =  delete $rect->{ start_c };
	delete $rect->@{qw/ dx dy start_x start_y /};
}



sub do {}



sub can_drop {
	my( $rect, $app_rect, $drop_x, $drop_y ) =  @_;

	my( $group, $child );
	for my $s ( $app_rect->{ children }->@* ) {
		$s != $rect   or next;
		my $curr =  $s->is_over( $drop_x, $drop_y )   or next;

		$group =  $s;
		$child =  $curr;
		# last;
		return $curr;
	}

}



sub can_group {
	my( $group, $square ) = @_;

	if( $group->{ x } < $square->{ x }
		&&  $group->{ y } < $square->{ y }
		&&  $group->{ x } + $group->{ w } > $square->{ x } + $square->{ w }
		&&  $group->{ y } + $group->{ h } > $square->{ y } + $square->{ h } ) {

		return $group;
	}
	return 1;
}



sub resize_group {
	my( $parent ) =  @_;

	my @children =  $parent->{ children }->@*;
	calc_group_size( $parent, \@children );

	if( $parent->{ parent }{ id } ) {
		resize_group( $parent->{ parent } );
	}
}



sub calc_group_size {
	my( $group, $children ) =  @_;

	my $w =   0;
	my $h =  10;

	for my $s ( @$children ) {
		$s->move_to( 10, $h );
		$s->{ c }{ r } =  $group->{ c }{ r } + 80;
		$s->store;

		$h +=  $s->{ h } +10;
		$w  =  $s->{ w } > $w ? $s->{ w } : $w;
	}

	$group->{ w } =  $w + 20;
	if( $group->{ w } < 50 ) {
		$group->{ w } =  50;
	}

	$group->{ h } =  $h;
	if( $group->{ h } < 30 ) {
		$group->{ h } =  30;
	}
}



sub move_to {
	my( $rect, $x, $y, $app_w, $app_h ) =  @_;

	$rect->{ x } =  $x - $rect->{ dx } //0;
	$rect->{ y } =  $y - $rect->{ dy } //0;

	if( $rect->{ x } < 0 ) {
		$rect->{ x } = 0;
	}
	if( $rect->{ y } < 0 ) {
		$rect->{ y } = 0;
	}

	if( $app_w  &&  $rect->{ x } > $app_w - $rect->{ w } ) {
		$rect->{ x } = $app_w - $rect->{ w };
	}
	if( $app_h  &&  $rect->{ y } > $app_h - $rect->{ h } ) {
		$rect->{ y } = $app_h - $rect->{ h };
	}
}



sub load_children {
	my( $rect ) = @_;

	my $child =  Util::db()->resultset( 'Rect' )->search({
		parent_id => $rect->{ id }
	});

	$rect->{ children } =  [ map{ Rect->new( $_ ) } $child->all ];
	for my $x ( $rect->{ children }->@* ) {
		$x->{ parent_id } =  $rect->{ id };############parent_id
		$x->{ parent } =  $rect;
		weaken $x->{ parent };

		$x->load_children;
	}
}



sub child_destroy {
	my( $square ) = @_;

	Util::db()->resultset( 'Rect' )->search({
		id => $square->{ id }
	})->delete;

	if( $square->{ children }->@* ) {

		for my $child ( $square->{ children }->@* ) {
			$child->child_destroy;
		}
	}
}



# sub detach {
# 	my( $rect, $app_rect ) =  @_;

# 	my $parent =  $rect->{ parent };
# 	my $children =  $parent->{ children };
# 	@$children =  grep{ $_ != $rect } @$children;
# }



# sub parent_coord {
# 	my( $rect, $x, $y ) =  @_;

# 	if( $rect->{ parent } ) {
# 		$x +=  $rect->{ parent }->{ x };
# 		$y +=  $rect->{ parent }->{ y };

# 		( $x, $y ) =  $rect->{ parent }->parent_coord( $x, $y );
# 	}

# 	return ( $x, $y );
# }




sub is_over_res_field {
	my( $shape, $x, $y ) =  @_;

	$shape->Util::resize_field( $x, $y );
}



sub resize_color {
	my( $rect ) =  @_;

	if( !$rect->{ start_c } ) {
		$rect->{ start_c  } =  $rect->{ c };
		$rect->{ c } =  Color->new( 0, 200, 0 );
	}
}



sub resize_to {
	my( $rect, $x, $y ) =  @_;

	$rect->{ w } =  $x - $rect->{ x };
	if( $x - $rect->{ x } < 50 ) {
		$rect->{ w } =  50;
	}

	$rect->{ h } =  $y - $rect->{ y };
	if( $y - $rect->{ y } < 30 ) {
		$rect->{ h } =  30;
	}


	$rect->{ children } or return;

	my $h = 10;
	for $square( $rect->{ children }->@* ) {
		$h +=  $square->{ h } + 10;

		if ( $rect->{ w } < $square->{ w } + 20 ) {
			$rect->{ w } =  $square->{ w } + 20;
		}
	}

	if( $rect->{ h } < $h ) {
		$rect->{ h } =  $h;
	}
}

sub on_mouse_over {
	my( $rect ) =  @_;

	# $rect->save_state;
	$rect->{ c }{ g } =  150;
}

sub on_mouse_out {
	my( $rect ) =  @_;

	$rect->{ c }{ g } =  220;
	# $rect->restore_state;
}

1;
