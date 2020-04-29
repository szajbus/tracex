# Tracex

[![hex.pm](https://img.shields.io/hexpm/v/tracex.svg?style=flat)](https://hex.pm/packages/tracex)
[![hexdocs.pm](https://img.shields.io/badge/docs-latest-green.svg?style=flat)](https://hexdocs.pm/tracex/)

Tracex is a tool for static analysis of mix projects.

It builds upon compiler tracing introduced in Elixir 1.10, simplifying collection of traces and turning them into valuable insights.

Tracex collects traces emitted by Elixir compiler and performs some basic data extraction and classification. The result, together with project's metadata built along the way, is available to the developer for further analysis.

Tracex automatically recognizes some common types of modules present in mix projects, like Ecto schemas or Phoenix controllers and views. Additionally it supports attaching custom classifiers that are specific to your project in order to collect extra information that may prove helpful in actual analysis.

Elixir compiler emits a lot of traces. For practical reasons tracex collets only ones that are local to your project. It means that any traces of interactions of your project's code with Elixir's core modules or external libraries are discarded.

## Motivation

Bad architectural decisions can lead to slow recompilation and negatively affect developer's workflow. Tracex was created to help me fight exactly this problem in an actual project.

It aims to aid in refactoring by providing insights into project's internal structure and interactions between the modules.

## Installation

The package can be installed by adding `tracex` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:tracex, "~> 0.1.0", only: :dev}
  ]
end
```

## Usage

First thing is to perform trace collection during project compilation.

```
iex> {project, traces} = Tracex.compile_project()
```

This compiles the project (with regular Elixir compiler), collects emitted traces and module information. It also dumps everything to disk in form of manifest file that can be later quickly reloaded in another iex session without recompilation.

```
iex> {project, traces} = Tracex.load_from_manifest()
```

`project` struct encapsulates information about project's modules and `traces` is a (possibly long) list of collected compiler traces.

```
iex> project.get_module(MyApp.Model.User)
%Tracex.Project.Module{
  extra: %{},
  file: "lib/models/user.ex",
  name: MyApp.Model.User,
  tags: [:ecto_schema]
}
```

By default module information is rather basic, but with help of custom classifiers modules can be annotated with extra information that is important in the context of your project (see [Classifiers](#classifiers) section).

### Filtering modules by annotations

Filtering by tags in built-in `Tracex.Project.get_modules/2`, extra annotations must be filtered manually.

```elixir
project
|> Tracex.Project.get_modules(tags: [:phoenix_controller, :phoenix_view])
|> Enum.filter(fn %{extra: extra} -> Map.get(extra, :context) == "Users" end)
```

### Module insights

To get some insights into how a module is used and how it interacts with other modules in your project use `Tracex.insights/2`

```
iex> Tracex.insights(traces, MyApp.Model.User)
%{
  inbound: [
    {:remote_function, MyApp.UserView, "full_name/1", "web/views/user_view.ex:14"},
    {:alias_reference, MyApp.UserView, "web/views/user_view.ex:14"},
    {:struct_expansion, MyApp.ReportGenerator, "lib/report_generator.ex:20"},
    {:alias_reference, MyApp.ReportGenerator, "lib/report_generator.ex:20"},
    ...
  ],
  outbound: [
    {:imported_macro, MyApp.I18n, "lib/models/user.ex:70"},
    {:imported_function, MyApp.Validators, "lib/models/user.ex:38"},
    {:remote_function, MyApp.Validators, "validate_password_strength/1", "lib/models/user.ex:31"},
    ...
  ]
}
```

Module insights encapsulate the information provided by compiler tracers. At the very minimum you can get some idea how the module interacts with others and possibly track down dependencies contributing to extensive recompilations in your project.


### Classifiers

Tracex is generic, it is able to extract some basic information about your project modules, but every project has its own unique characteristics, like naming conventions or usage of certain macros. Classifiers make it easy to leverage that tacit knowledge to annotate your project's modules.

For example, you may want to focus your analysis on some specific classes of modules, like event handlers or query builders. Or take a broader view and group modules in contexts to analyze cross-context dependencies. By annotating modules accordingly, it will be later easier to perform actual analysis.

Tracex currently supports two types of annotations: tags and extra attributes.

You have already seen tags usage in the example above with `MyApp.Models.User` module being tagged as `:ecto_schema`. Tracex's built-in classifier automatically tags a module that way when it detects use of `use Ecto.Schema` in module's body. Analogically it is able to tag modules as `:phoenix_controller`, `:phoenix_view`, `:phoenix_router` or `:phoenix_channel`. See `Tracex.Classifier` for more details.

As tags are supposed to be a list of atoms, extra attributes is a map to keep anything you'd find useful. For example, name of a context a module is in.

The only requirement for a custom classifier module is to implement `classify/1` function that accepts compiler trace as argument and returns a list module annotations.

```elixir
defmodule MyClassifier do
  # import some helper functions to easily work with compiler traces
  # See `Tracex.Trace` for full list
  import Tracex.Trace, only: [
    module_definition?: 1,
    macro_usage?: 2,
    outbound_module: 2,
    event_location: 1
  ]

  def classify(trace) do
    module = outbound_module(trace)

    cond do
      module_definition?(trace) ->
        # annotate module with context information
        {:extra, module, :context, extract_context_from_module_name(module)}

      macro_usage?(trace, MyApp.QueryBuilder) ->
        # assuming query builder modules in your project make use of
        # `use MyApp.QueryBuilder`, you can detect that using `macro_usage?/2`
        {:tag, module, :query_builder}

      String.starts_with?(event_location?(trace), "web/controllers/api/v1/") ->
        # annotate module with API version number and tag as :legacy
        [{:extra, module, :version, 1}, {:tag, module, :legacy}]

      String.starts_with?(event_location(trace), "web/controllers/api/v2/") ->
        # annotate module with API version number
        {:extra, module, :version, 2}

      String.starts_with?(event_location(trace), "apps/") ->
        # annotate module with umbrella app name
        {:extra, module, :umbrella_app, extract_app_from_path(event_location(trace))}

      true ->
        nil
    end
  end

  defp extract_context_from_module_name(module) do
    # custom logic to map module name to context name
  end

  defp extract_app_from_path(path) do
    # regex-based extraction
  end
end
```

Note that **custom classifiers should not use any code from your project** because it will not be available during compilation.

To use a custom classifier module you must compile it manually before supplying to `Tracex.compile_project/1`.

```
iex> c "my_classifier.exs"
iex> Tracex.compile_project(custom_classifiers: [MyClassifier])
```

## State of the library

Tracex is highly experimental and completely untested. The interface is a subject to change.

## Roadmap

* annotating traces by type of dependency (compile-time or runtime) they create between modules, although I'm not sure it's possible to get it 100% right with the information currently provided by compiler traces

* support for visualizations, e.g. using hierarchical edge bundling

* cycle detection in module dependency graph

* ...

## Documentation

Documentation is available at [https://hexdocs.pm/tracex](https://hexdocs.pm/tracex).

## License

[MIT](LICENSE)
