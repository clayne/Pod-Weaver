package Pod::Weaver::Section::Bugs;
# ABSTRACT: a section for bugtracker info

use Moose;
use Text::Wrap ();
with 'Pod::Weaver::Role::Section';

# BEGIN BOILERPLATE
use v5.20.0;
use warnings;
use utf8;
no feature 'switch';
use experimental qw(postderef postderef_qq); # This experiment gets mainlined.
# END BOILERPLATE

=head1 OVERVIEW

This section plugin will produce a hunk of Pod giving bug reporting
information for the document, like this:

  =head1 BUGS

  Please report any bugs or feature requests on the bugtracker website
  http://rt.cpan.org/Dist/Display.html?Queue=Pod-Weaver

  When submitting a bug or request, please include a test-file or a
  patch to an existing test-file that illustrates the bug or desired
  feature.

This plugin requires a C<distmeta> parameter containing a hash reference of
L<CPAN::Meta::Spec> distribution metadata and at least one of one of the
parameters C<web> or C<mailto> defined in
C<< $meta->{resources}{bugtracker} >>.

=head2 Using Pod::Weaver::Section::Bugs with Dist::Zilla

When the PodWeaver plugin is used, the C<distmeta> parameter comes from the
dist's distmeta data.  Since this section is skipped when no bugtracker data is
in the distmeta, you'll need to make sure it's there.  A number of plugins set
this data up automatically.  To manually configure your bugtracker data, you
can add something like the following to C<dist.ini>:

  [MetaResources]
  bugtracker.web = http://rt.cpan.org/NoAuth/Bugs.html?Dist=Pod-Weaver-Example
  bugtracker.mailto = bug-pod-weaver-example@rt.cpan.org

  ; Perhaps add repository stuff here:
  repository.url =
  repository.web =
  repository.type =

  [PodWeaver]

=attr header

The title of the header to be added.
(default: "BUGS")

=cut

has header => (
  is      => 'ro',
  isa     => 'Str',
  default => 'BUGS',
);

sub weave_section {
  my ($self, $document, $input) = @_;

  unless (exists $input->{distmeta}{resources}{bugtracker}) {
    $self->log_debug('skipping section because there is no resources.bugtracker');
    return;
  }
  my $bugtracker = $input->{distmeta}{resources}{bugtracker};
  my ($web, $mailto) = $bugtracker->@{ qw(web mailto) };

  unless (defined $web || defined $mailto) {
    $self->log_debug('skipping section because there is no web or mailto key under resources.bugtracker');
    return;
  }

  my $text = "Please report any bugs or feature requests ";

  my $name = $self->header;
  if (defined $web) {
    $self->log_debug("including $web as bugtracker in $name section");
    $text .= "on the bugtracker website L<$web>";
    $text .= defined $mailto ? " or " : "\n";
  }

  if (defined $mailto) {
    $self->log_debug("including $mailto as bugtracker in $name section");
    $text .= "by email to L<$mailto|mailto:$mailto>\.\n";
  }

  local $Text::Wrap::huge = 'overflow';
  $text = Text::Wrap::wrap(q{}, q{}, $text);

  $text .= <<'HERE';

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.
HERE

  push $document->children->@*,
    Pod::Elemental::Element::Nested->new({
      command  => 'head1',
      content  => $name,
      children => [
        Pod::Elemental::Element::Pod5::Ordinary->new({ content => $text }),
      ],
    });
}

__PACKAGE__->meta->make_immutable;
1;
