package RefreshAndPublish::Plugin;

use strict;
use Carp qw( croak );

sub cond {
    my $app = MT->app;                                                                                                             
    my $tmpl_type = $app->param('filter_key');                                                                                     
    return $app->mode eq 'itemset_action'  ? 1                                                                                     
	: !$app->blog                     ? 0                                                                                     
	: !$tmpl_type                     ? 0                                                                                     
	: $tmpl_type eq 'index_templates' ? 1                                                                                     
	:                                   0                                                                                     
	;                                                                                                                         
}                                                                                                                                 

sub refpub {
    my $app = shift;
    $app->validate_magic or return;

    # permission check
    my $perms = $app->permissions;
    return $app->errtrans("Permission denied.")
        unless $app->user->is_superuser ||
            $perms->can_administer_blog ||
            $perms->can_rebuild;

    require MT::CMS::Template;
    MT::CMS::Template::refresh_individual_templates($app);

    my $blog = $app->blog;
    my $templates = MT->model('template')->lookup_multi([ $app->param('id') ]);
    TEMPLATE: for my $tmpl (@$templates) {
        next TEMPLATE if !defined $tmpl;
        next TEMPLATE if $tmpl->blog_id != $blog->id;
        next TEMPLATE unless $tmpl->build_type;

        $app->rebuild_indexes(
            Blog     => $blog,
            Template => $tmpl,
            Force    => 1,
        );
    }

    $app->call_return( published => 1 );
}

1;
