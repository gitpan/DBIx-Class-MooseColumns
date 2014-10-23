package DBIx::Class::MooseColumns::Meta::Role::Attribute::DBICColumn::Inflated;

use Moose::Role;
use namespace::autoclean;

=head1 NAME

DBIx::Class::MooseColumns::Meta::Role::Attribute::DBICColumn - Attribute metaclass trait for DBIx::Class::MooseColumns for attributes that are inflated DBIC columns

=cut

=head1 METHODS

=cut

=head2 has_value

Overridden (wrapped with an C<around> method modifier) from
L<Class::MOP::Attribute/has_value>.

Calls L<DBIx::Class::Row/has_column_loaded> to check if the column is
initialized.

=cut

around has_value => sub {
  my ($orig, $self, $instance) = (shift, shift, @_);

  return $instance->has_column_loaded($self->name);
};

=head2 get_raw_value

Overridden (wrapped with an C<around> method modifier) from
L<Class::MOP::Attribute/get_raw_value>.

Calls L<DBIx::Class::Row/get_inflated_column> to get the (deflated) column value.

=cut

around get_raw_value => sub {
  my ($orig, $self, $instance) = (shift, shift, @_);

  return $instance->get_inflated_column($self->name);
};

=head2 set_raw_value

Overridden (wrapped with an C<around> method modifier) from
L<Class::MOP::Attribute/set_raw_value>.

Calls L<DBIx::Class::Row/set_inflated_column> to set the (deflated) column value.

=cut

around set_raw_value => sub {
  my ($orig, $self, $instance, $value) = (shift, shift, @_);

  return $instance->set_inflated_column($self->name, $value);
};

=head2 clear_value

Overridden (wrapped with an C<around> method modifier) from
L<Class::MOP::Attribute/clear_value>.

Currently unimplemented. (DBIC has no public API for this operation currently)

=cut

my $clearer_unimplemented_error_msg
  =   "Calling the clearer method on a DBIC column attributes is unimplemented "
    . "currently. (DBIC has no public API for this operation currently)";

around clear_value => sub {
  my ($orig, $self, $instance) = (shift, shift, @_);

  #FIXME come up with a DBIC patch to create an ->unload_column() method
  # proposed implementation (has to be checked if it properly cleans up):
  #delete $instance->{_inflated_column}{$self->name};
  #delete $instance->{_column_data}{$self->name}
  #return;

  $instance->throw_exception($clearer_unimplemented_error_msg);
};

=head2 _set_initial_slot_value

Overridden (wrapped with an C<around> method modifier) from
L<Class::MOP::Attribute/_set_initial_slot_value>.

Calls L<DBIx::Class::Row/set_column> to set the (deflated) column value.

=cut

around _set_initial_slot_value => sub {
  my ($orig, $self, $meta_instance, $instance, $value) = (shift, shift, @_);

  my $slot_name = $self->name;

  return $instance->set_column($slot_name, $value)
    unless $self->has_initializer;

  my $callback = sub {
    my $val = $self->_coerce_and_verify(shift, $instance);

    return $instance->set_column($slot_name, $_[0])
  };
  
  my $initializer = $self->initializer;

  return $instance->$initializer($value, $callback, $self);
};


=head2 inline_has

Overridden (wrapped with an C<around> method modifier) from
L<Class::MOP::Attribute/inline_has>.

Calls L<DBIx::Class::Row/has_column_loaded> to check if the column is
initialized.

=cut

around inline_has => sub {
  my ($orig, $self, $instance) = (shift, shift, @_);

  return sprintf q[%s->has_column_loaded("%s")],
    $instance, quotemeta($self->name);
};

=head2 inline_get

Overridden (wrapped with an C<around> method modifier) from
L<Class::MOP::Attribute/inline_get>.

Calls L<DBIx::Class::Row/get_inflated_column> to get the (deflated) column value.

=cut

around inline_get => sub {
  my ($orig, $self, $instance) = (shift, shift, @_);

  return sprintf q[%s->get_inflated_column("%s")],
    $instance, quotemeta($self->name);
};

=head2 inline_set

Overridden (wrapped with an C<around> method modifier) from
L<Class::MOP::Attribute/inline_set>.

Calls L<DBIx::Class::Row/set_inflated_column> to set the (deflated) column value.

=cut

around inline_set => sub {
  my ($orig, $self, $instance, $value) = (shift, shift, @_);

  return sprintf q[%s->set_inflated_column("%s", %s)],
    $instance, quotemeta($self->name), $value;
};

=head2 inline_clear

Overridden (wrapped with an C<around> method modifier) from
L<Class::MOP::Attribute/inline_clear>.

Currently unimplemented. (DBIC has no public API for this operation currently)

=cut

around inline_clear => sub {
  my ($orig, $self, $instance) = (shift, shift, @_);

  #FIXME see comments at L</clear_value>

  return sprintf q[%s->throw_exception("%s");],
    $instance, $clearer_unimplemented_error_msg;
};

1;
