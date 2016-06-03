# CONTRIBUTING

To contribute code to this repository, simply submit a PR. Try to follow
a similar code style. **Please note:** your PR might get rejected for any
reason. If you're making substantial changes, please consult with the author
whether the change is desirable, by opening an Issue.

To contribute an article, follow these instructions:

### Create Post File

Create a file in [`/post`
directory](https://github.com/zoffixznet/perl6.party/tree/master/post). Name
the file similar to what the title of your article is, changing any non-English-digit and non-English-letter characters to hyphens (`-`), and use `.md`
extension.

### Meta Data

Add post's meta data at the very top of the file. Each field follows the format
`%% fieldname: fieldvalue` and cannot be broken up onto multiple lines.

##### Mandatory Fields

These fields must be present in the article you contribute:

```
    %% title: Bit Rot Thursday
    %% date: 2016-01-27
    %% desc: A plan to combat Bit Rot in software. Cause and solutions.
    %% author: Zoffix Znet
```

The `title` is the title of your article, `date` is the published date,
`desc` is a short description, and `author` is your name.
This is all just text, not markup, so you don't
have to escape any special HTML characters.

##### Optional Fields

These are optional fields. You can omit them, if you don't find them
relevant:

```
    %% author-email: cpan@zoffix.com
    %% author-twitter: @zoffix
    %% license: Artistic License 2.0
```

The `author-email` is an email address readers can use to contact you,
`author-twitter` is your Twitter handle, `license` is the license for your
article. The [`LICENSE` file](LICENSE) states explicit permission by you to
reproduce the article is required, if the `%% license` field is not specified.
