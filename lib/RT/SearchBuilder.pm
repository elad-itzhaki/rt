#$Header: /raid/cvsroot/rt/lib/RT/SearchBuilder.pm,v 1.4 2001/12/04 01:13:42 jesse Exp $

=head1 NAME

  RT::SearchBuilder - a baseclass for RT collection objects

=head1 SYNOPSIS

=head1 DESCRIPTION


=head1 METHODS


=begin testing

ok (require RT::SearchBuilder);

=end testing


=cut

package RT::SearchBuilder;

use RT::Base;
use DBIx::SearchBuilder;

use vars qw(@ISA);
@ISA = qw(DBIx::SearchBuilder RT::Base);

# {{{ sub _Init 
sub _Init  {
    my $self = shift;
    
    $self->{'user'} = shift;
    unless(defined($self->CurrentUser)) {
	use Carp;
	Carp::confess("$self was created without a CurrentUser");
	$RT::Logger->err("$self was created without a CurrentUser");
	return(0);
    }
    $self->SUPER::_Init( 'Handle' => $RT::Handle);
}
# }}}

# {{{ sub LimitToEnabled

=head2 LimitToEnabled

Only find items that haven\'t been disabled

=cut

sub LimitToEnabled {
    my $self = shift;
    
    $self->Limit( FIELD => 'Disabled',
		  VALUE => '0',
		  OPERATOR => '=' );
}
# }}}

# {{{ sub LimitToDisabled

=head2 LimitToDeleted

Only find items that have been deleted.

=cut

sub LimitToDeleted {
    my $self = shift;
    
    $self->{'find_disabled_rows'} = 1;
    $self->Limit( FIELD => 'Disabled',
		  OPERATOR => '=',
		  VALUE => '1'
		);
}
# }}}

# {{{ sub Limit 

=head2 Limit PARAMHASH

This Limit sub calls SUPER::Limit, but defaults "CASESENSITIVE" to 1, thus
making sure that by default lots of things don't do extra work trying to 
match lower(colname) agaist lc($val);

=cut

sub Limit {
	my $self = shift;
	my %args = ( CASESENSITIVE => 1,
		     @_ );

   return $self->SUPER::Limit(%args);
}

# }}}

# {{{ sub ItemsArrayRef

=item ItemsArrayRef

Return this object's ItemsArray.
If it has a SortOrder attribute, sort the array by SortOrder.
Otherwise, if it has a "Name" attribute, sort alphabetically by Name
Otherwise, just give up and return it in the order it came from the db.

=cut

=begin testing

use_ok(RT::Queues);
ok(my $queues = RT::Queues->new($RT::SystemUser), 'Created a queues object');
ok( $queues->UnLimit(),'Unlimited the result set of the queues object');
my $items = $queues->ItemsArrayRef();
my @items = @{$items};

ok($queues->NewItem->_Accessible('Name','read'));
my @sorted = sort {$a->Name cmp $b->Name} @items;

my @sorted_ids = map {$_->id } @sorted;
my @items_ids = map {$_->id } @items;


is ($sorted[0]->Name, $items[0]->Name);
is ($sorted[-1]->Name, $items[-1]->Name);
is_deeply(\@items_ids, \@sorted_ids, "ItemsArrayRef sorts alphabetically by name");;

=end testing

sub ItemsArrayRef {
    my $self = shift;
    my $items;
    
    if ($self->NewItem()->_Accessible('SortOrder','read')) {
        $items = sort { $a->SortOrder <=> $b->SortOrder } @{$self->SUPER::ItemsArrayRef()};
    }
    elsif ($self->NewItem()->_Accessible('name','read')) {
        $items = sort { $a->Name cmp $b->Name } @{$self->SUPER::ItemsArrayRef()};
    }
    else {
        $titems = $self->SUPER::ItemsArrayRef();
    }

    return($items);

}

# }}}

1;


