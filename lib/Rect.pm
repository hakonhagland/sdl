package Rect;

# use strict;
# use warnings;


use Scalar::Util qw(weaken);
use SDL::Event;

use AppRect;
use Color;
use Shape;


use base 'Shape';

my $MAX_H =  500;
my $MAX_W =  500;

my $MIN_H =  30;
my $MIN_W =  50;

my $START_H =  30;
my $START_W =  50;

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


	my( $rect, $x, $y, $w, $h, $c, $l ) =  @_;

	$x //=  ($x_offset += 30);
	$y //=  $y_offset_n * 5  + ($y_offset +=  10);

	if( $x_offset > 600 ) {
		$x_offset =  40;
		$y_offset =  50;
		$y_offset_n++;
	}

	$rect =  $rect->SUPER::new();

	my %rect = (
		x         => $x,
		y         => $y,
		w         => $w // $START_W,
		h         => $h // $START_H,
		c         => $c // Color->new,
		highlight => $l // Color->new( 255, 0, 0, 255 ),

		min_h     => $MIN_H,
		min_w     => $MIN_W,
		max_h     => $MAX_H,
		max_w     => $MAX_W,

		status    => 'Rect',
	);
	$rect->@{ keys %rect } =  values %rect;


	return $rect;
}



## Сохраняет состояние объекта для draw_black перед его следующей отрисовкой
sub save_draw_coord {
	my( $rect ) =  @_;

	$rect->SUPER::save_draw_coord;

	$rect->{ ow } =  $rect->{ w };
	$rect->{ oh } =  $rect->{ h };
}



sub mouse_target {
	my( $object, $x, $y ) =  @_;

	return $x >= $object->{ x }
		&& $x <= $object->{ x } + $object->{ w }
		&& $y >= $object->{ y }
		&& $y <= $object->{ y } + $object->{ h }
}



# Делает проверку, что объект $rect находится внутри квадрата x,y,w,h
sub is_inside {
	my( $rect, $x, $y, $w, $h ) =  @_;

	return $rect->{ x } > $x  &&  $rect->{ x } + $rect->{ w } < $x + $w
		&& $rect->{ y } > $y  &&  $rect->{ y } + $rect->{ h } < $y + $h;
}



## Запись в базу parent_id для объекта
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



## Сохранение состояние объекта
sub save_state {
	my( $rect ) =  @_;


	$rect->{ start_x } =  $rect->{ x };
	$rect->{ start_y } =  $rect->{ y };

	$rect->{ start_c } =  $rect->{ c };
}



## Восстановление  состояния объекта
sub restore_state {
	my( $rect ) =  @_;

	$rect->{ c } =  delete $rect->{ start_c };
	delete $rect->@{qw/ start_x start_y /};
}


## Проверка условия, при котором возможно выполнить drop для объекта
## Проверка - находится ли объект над другим объектом(возвращает этот объект)
sub can_drop {
	my( $rect, $drop_x, $drop_y, $h ) =  @_;

	my( $group, $child );
	for my $s ( $h->{ app }{ children }->@* ) {
		$s != $rect   or next;
		my $curr =  $s->is_over( $drop_x, $drop_y )   or next;

		$group =  $s;
		$child =  $curr;
		# last;
		return $curr;
	}

}


## Проверяет, попали ли в группу выделения объекты
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


## Пересчитывает размер группы(каждого объекта группы, который требует пересчёта)
sub resize_group {
	my( $parent ) =  @_;

	my @children =  $parent->{ children }->@*;
	$parent->organize_group( \@children );

	if( $parent->{ parent }{ id } ) {
		$parent->{ parent }->resize_group;
	}
}



sub set_group_size {
	my( $circle, $h, $w ) =  @_;

	$h =  $h < 30 ? 30 : $h;
	$w =  $w < 50 ? 50 : $w;

	$circle->{ min_h } =  $circle->{ h } =  $h;
	$circle->{ min_w } =  $circle->{ w } =  $w;
}



sub get_points {
	my( $rect ) =  @_;

	return
		[ $rect->{ x }              , $rect->{ y }               ],
		[ $rect->{ x } +$rect->{ w }, $rect->{ y }               ],
		[ $rect->{ x }              , $rect->{ y } +$rect->{ h } ],
		[ $rect->{ x } +$rect->{ w }, $rect->{ y } +$rect->{ h } ],
	;
}



sub clip {
	my( $rect, $w, $h ) =  @_;

	if( my $p =  $rect->{ parent } ) {
		$w //=  $p->{ w };
		$h //=  $p->{ h };
	}

	if( $rect->{ x } < 0 ) {
		$rect->{ x } = 0;
	}
	if( $rect->{ y } < 0 ) {
		$rect->{ y } = 0;
	}

	if( $w  &&  $rect->{ x } > $w - $rect->{ w } ) {
		$rect->{ x } = $w - $rect->{ w };
	}
	if( $h  &&  $rect->{ y } > $h - $rect->{ h } ) {
		$rect->{ y } = $h - $rect->{ h };
	}
}



## Удаляет объект(пришедший в функцию) из числа детей его родителя
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



## Проверяет находится ли курсор над полем для изменения размеров объекта
sub is_over_res_field {
	my( $rect, $x, $y ) =  @_;

	return $x > $rect->{ x } + $rect->{ w } - 15
		&& $x < $rect->{ x } + $rect->{ w }
		&& $y > $rect->{ y } + $rect->{ h } - 10
		&& $y < $rect->{ y } + $rect->{ h }
}



## Изменяет цвет объекта при изменении его размеров(запоминает исходный цвет)
sub resize_color {
	my( $rect ) =  @_;

	if( !$rect->{ start_c } ) {
		$rect->{ start_c  } =  $rect->{ c };
		$rect->{ c } =  Color->new( 0, 200, 0 );
	}
}



## Возвращает размер объекта для resize
sub calc_size_values {
	my( $rect, $x, $y ) =  @_;

	my $h =  $y - $rect->{ y };
	my $w =  $x - $rect->{ x };

	return ( $h, $w );
}



## Size_batton coords
sub get_sb_coords {
	my( $rect, $x, $y ) =  @_;

	return (
		$x + $rect->{ w } - 15,
		$y + $rect->{ h } - 10,
		15,10,
	);
}



## Меняет цвет объекта, над которым курсор
sub on_mouse_over {
	my( $rect ) =  @_;

	$rect->{ c }{ r } =  200;
}



## Возвращает цвет объекту, над которым был курсор
sub on_mouse_out {
	my( $rect ) =  @_;

	$rect->{ c }{ r } =  23;
}



sub on_press {
	my( $shape, $h, $e ) =  @_;

}


# sub on_keydown {
# 	my( $rect, $h, $e ) =  @_;

# 	$h->{ app }{ event_state }{ SDLK_d() }
# 		or return;


# 	if( $rect->{ my_d } ) {
# 		delete $rect->{ my_d };
# 	}
# 	else {
# 		$rect->{ my_d } =  1;
# 	}

# 	printf "MY D: %s\n", $rect->{ my_d };
# }



1;
