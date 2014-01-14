function buildTopRoute(filter) {
  return Discourse.Route.extend({
    renderTemplate: function() {
      this.render('navigation/default', { outlet: 'navigation-bar' });
      this.render('discovery/topics', { controller: 'discoveryTopics', outlet: 'list-container' });
    },

    beforeModel: function() {
      this.controllerFor('navigationDefault').set('filterMode', filter);
    },

    model: function() {
      return Discourse.TopicList.list(filter).then(function(list) {
        var tracking = Discourse.TopicTrackingState.current();
        if (tracking) {
          tracking.sync(list, filter);
          tracking.trackIncoming(filter);
        }
        return list;
      });
    },

    setupController: function(controller, model) {
      this.controllerFor('discoveryTopics').set('model', model);
      this.controllerFor('navigationDefault').set('canCreateTopic', model.get('can_create_topic'));
    }
  });
}
function buildTopicRoute(filter) {
  return Discourse.Route.extend({
    renderTemplate: function() {
      this.render('navigation/default', { outlet: 'navigation-bar' });
      this.render('discovery/topics', { controller: 'discoveryTopics', outlet: 'list-container' });
    },

    beforeModel: function() {
      this.controllerFor('navigationDefault').set('filterMode', filter);
    },

    model: function() {
      return Discourse.TopicList.list(filter).then(function(list) {
        var tracking = Discourse.TopicTrackingState.current();
        if (tracking) {
          tracking.sync(list, filter);
          tracking.trackIncoming(filter);
        }
        return list;
      });
    },

    setupController: function(controller, model) {
      this.controllerFor('discoveryTopics').set('model', model);
      this.controllerFor('navigationDefault').set('canCreateTopic', model.get('can_create_topic'));
    }
  });
}

Discourse.DiscoveryRoute = Discourse.Route.extend({
  actions: {
    loading: function() {
      this.controllerFor('discovery').set('loading', true);
    },

    loadingComplete: function() {
      this.controllerFor('discovery').set('loading', false);
    },

    didTransition: function() {
      this.send('loadingComplete');
    }
  }
});

function buildCategoryRoute(filter, params) {
  return Discourse.Route.extend({
    renderTemplate: function() {
      this.render('navigation/category', { outlet: 'navigation-bar' });
      this.render('discovery/topics', { controller: 'discoveryTopics', outlet: 'list-container' });
    },

    model: function(params) {
      return Discourse.Category.findBySlug(params.slug, params.parentSlug);
    },

    afterModel: function(model) {
      var self = this,
          noSubcategories = params && !!params.no_subcategories,
          filterMode = "category/" + Discourse.Category.slugFor(model) + (noSubcategories ? "/none" : "") + "/l/" + filter,
          listFilter = "category/" + Discourse.Category.slugFor(model) + "/l/" + filter;

      this.controllerFor('search').set('searchContext', model);

      var opts = { category: model, filterMode: filterMode };
      opts.noSubcategories = params && params.no_subcategories;
      opts.canEditCategory = Discourse.User.current('staff');
      this.controllerFor('navigationCategory').setProperties(opts);

      return Discourse.TopicList.list(listFilter, params).then(function(list) {
        var tracking = Discourse.TopicTrackingState.current();
        if (tracking) {
          tracking.sync(list, listFilter);
          tracking.trackIncoming(listFilter);
        }

        // If all the categories are the same, we can hide them
        var diffCat = list.get('topics').find(function (t) {
          return t.get('category') !== model;
        });
        if (!diffCat) { list.set('hideCategory', true); }
        self.set('topics', list);
      });
    },

    setupController: function() {
      var topics = this.get('topics');
      this.controllerFor('discoveryTopics').set('model', topics);
      this.controllerFor('navigationCategory').set('canCreateTopic', topics.get('can_create_topic'));
      this.set('topics', null);
    },

    deactivate: function() {
      this._super();
      this.controllerFor('search').set('searchContext', null);
    }
  });
}

Discourse.DiscoveryTopRoute = Discourse.Route.extend({

  model: function(params) {
    var category = Discourse.Category.findBySlug(params.slug, params.parentSlug);
    if (category) { this.set('category', category); }

    return Discourse.TopList.find(this.period, category);
  }

});

Discourse.DiscoveryCategoriesRoute = Discourse.Route.extend({
  renderTemplate: function() {
    this.render('navigation/categories', { outlet: 'navigation-bar' });
    this.render('discovery/categories', { outlet: 'list-container' });
  },

  beforeModel: function() {
    this.controllerFor('navigationCategories').set('filterMode', 'categories');
  },

  model: function() {
    return Discourse.CategoryList.list('categories').then(function(list) {
      var tracking = Discourse.TopicTrackingState.current();
      if (tracking) {
        tracking.sync(list, 'categories');
        tracking.trackIncoming('categories');
      }
      return list;
    });
  }, 

  setupController: function(controller, model) {
    controller.set('model', model);
    this.controllerFor('navigationCategories').set('canCreateCategory', model.get('can_create_category'));
  },

  actions: {
    createCategory: function() {
      Discourse.Route.showModal(this, 'editCategory', Discourse.Category.create({
        color: 'AB9364', text_color: 'FFFFFF', hotness: 5, group_permissions: [{group_name: 'everyone', permission_type: 1}],
        available_groups: Discourse.Site.current().group_names
      }));
      this.controllerFor('editCategory').set('selectedTab', 'general');
    }
  },
});

Discourse.DiscoveryController = Em.Controller.extend({});
Discourse.DiscoveryCategoryRoute = buildCategoryRoute('latest');
Discourse.DiscoveryCategoryNoneRoute = buildCategoryRoute('latest', {no_subcategories: true});

Discourse.ListController.FILTERS.forEach(function(filter) {
  Discourse["Discovery" + filter.capitalize() + "Route"] = buildTopicRoute(filter);
  Discourse["Discovery" + filter.capitalize() + "CategoryRoute"] = buildCategoryRoute(filter);
  Discourse["Discovery" + filter.capitalize() + "CategoryNoneRoute"] = buildCategoryRoute(filter, {no_subcategories: true});
});

Discourse.TopList.PERIODS.forEach(function(period) {
  Discourse["DiscoveryTop" + period.capitalize() + "Route"] = buildTopRoute('top/' + period);
});

Discourse.NavigationDefaultController = Discourse.Controller.extend({
  needs: ['composer', 'discoveryTopics'],

  actions: {
    createTopic: function() {
      var topicsController = this.get('controllers.discoveryTopics');
      this.get('controllers.composer').open({
        categoryId: this.get('category.id'),
        action: Discourse.Composer.CREATE_TOPIC,
        draft: topicsController.get('draft'),
        draftKey: topicsController.get('draft_key'),
        draftSequence: topicsController.get('draft_sequence')
      });
    }
  },

  categories: function() {
    return Discourse.Category.list();
  }.property(),

  navItems: function() {
    return Discourse.NavItem.buildList();
  }.property() 
});

Discourse.NavigationCategoryController = Discourse.NavigationDefaultController.extend({
  navItems: function() {
    return Discourse.NavItem.buildList(this.get('category'), { noSubcategories: this.get('noSubcategories') });
  }.property('category', 'noSubcategories') 
});

Discourse.NavigationCategoriesController = Discourse.NavigationDefaultController.extend({});

Discourse.DiscoveryTopicsController = Discourse.ObjectController.extend({

  actions: {
    // Star a topic
    toggleStar: function(topic) {
      topic.toggleStar();
    },

    // clear a pinned topic
    clearPin: function(topic) {
      topic.clearPin();
    },

    // Show newly inserted topics
    showInserted: function() {
      var tracker = Discourse.TopicTrackingState.current();

      // Move inserted into topics
      this.get('content').loadBefore(tracker.get('newIncoming'));
      tracker.resetTracking();
      return false;
    },

    refresh: function() {
      var filter = this.get('model.filter'),
          self = this;

      this.send('loading');
      Discourse.TopicList.find(filter).then(function(list) {
        self.set('model', list);
        self.send('loadingComplete');
      });
    }
  },

  topicTrackingState: function() {
    return Discourse.TopicTrackingState.current();
  }.property(),

  hasTopics: Em.computed.gt('topics.length', 0),
  showTable: Em.computed.or('hasTopics', 'topicTrackingState.hasIncoming'),
  latest: Ember.computed.equal('filter', 'latest'),
  allLoaded: Em.computed.empty('more_topics_url'),

  updateTitle: function(){
    Discourse.notifyTitle(this.get('topicTrackingState.incomingCount'));
  }.observes('topicTrackingState.incomingCount'),

  footerMessage: function() {
    if (!this.get('allLoaded')) { return; }

    var category = this.get('category');
    if( category ) {
      return I18n.t('topics.bottom.category', {category: category.get('name')});
    } else {
      var split = this.get('filter').split('/');
      if (this.get('topics.length') === 0) {
        return I18n.t("topics.none." + split[0], {
          category: split[1]
        });
      } else {
        return I18n.t("topics.bottom." + split[0], {
          category: split[1]
        });
      }
    }
  }.property('allLoaded', 'topics.length'),

  loadMoreTopics: function() {
    var topicList = this.get('model');
    return topicList.loadMore().then(function(moreUrl) {
      if (!Em.isEmpty(moreUrl)) {
        Discourse.URL.replaceState(Discourse.getURL("/") + topicList.get('filter') + "/more");
      }
    });
  }
});

Discourse.DiscoveryTopicsView = Discourse.View.extend(Discourse.LoadMore, {
  eyelineSelector: '.topic-list-item',

  _scrollTop: function() {
    Em.run.schedule('afterRender', function() {
      $('document').scrollTop(0);
    });
  }.on('didInsertElement'),

  actions: {
    loadMore: function() {
      var self = this;
      Discourse.notifyTitle(0);
      self.get('controller').loadMoreTopics().then(function (hasMoreResults) {
        Em.run.schedule('afterRender', function() {
          self.saveScrollPosition();
        });
        if (!hasMoreResults) {
          self.get('eyeline').flushRest();
        }
      });
    }
  },

  // Remember where we were scrolled to
  saveScrollPosition: function() {
    Discourse.Session.current().set('topicListScrollPosition', $(window).scrollTop());
  },

  // When the topic list is scrolled
  scrolled: function() {
    this._super();
    this.saveScrollPosition();
  }
});
